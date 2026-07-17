import SwiftUI
import WebKit
import Combine

// 内置浏览器提取器：用于 B站等反爬页面
// 用真实 WebKit 渲染页面，由用户确认后提取正文文字交给后端

// MARK: - Bridge

final class WebBridge: NSObject, @unchecked Sendable {
    let webView: WKWebView

    override init() {
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: config)
        super.init()
    }

    func load(_ url: URL) {
        var req = URLRequest(url: url)
        req.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        webView.load(req)
    }

    @MainActor
    func extractText() async -> String? {
        // 依次尝试 B站 opus 正文 → 通用文章容器 → 全页 body
        let js = """
        (function() {
            const selectors = [
                '.opus-module-content',
                '.bili-rich-text',
                '.article-detail__content',
                '#article-content',
                'article',
                '.article-content',
                'main'
            ];
            for (const sel of selectors) {
                const el = document.querySelector(sel);
                if (el && el.innerText.trim().length > 100) return el.innerText.trim();
            }
            return document.body.innerText.trim();
        })()
        """
        return (try? await webView.evaluateJavaScript(js)) as? String
    }
}

// MARK: - UIViewRepresentable

struct WebViewRepresentable: UIViewRepresentable {
    let bridge: WebBridge
    func makeUIView(context: Context) -> WKWebView { bridge.webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// MARK: - Sheet View

struct WebExtractorSheet: View {
    let url: URL
    let onExtracted: (String, URL) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var bridge       = WebBridge()
    @State private var isLoading    = true
    @State private var isExtracting = false
    @State private var extractError = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                WebViewRepresentable(bridge: bridge)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(edges: .bottom)

                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("页面加载中…")
                            .font(.caption).fontWeight(.medium)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.top, 8)
                }
            }
            .navigationTitle("加载公告页面")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isExtracting {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Button("提取内容") {
                            Task { await extract() }
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.hoyoPink)
                        .disabled(isLoading)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Text("页面加载完成后点「提取内容」。如遇验证码请手动完成再提取。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(.regularMaterial)
            }
            .alert("未能提取内容", isPresented: $extractError) {
                Button("好") {}
            } message: {
                Text("页面内容为空或尚未加载完成，请等待页面完全加载后再试。")
            }
        }
        .onAppear { bridge.load(url) }
        .onReceive(bridge.webView.publisher(for: \.isLoading)) { isLoading = $0 }
    }

    private func extract() async {
        isExtracting = true
        let text = await bridge.extractText()
        if let text, text.count > 50 {
            onExtracted(text, bridge.webView.url ?? url)
            dismiss()
        } else {
            extractError = true
            isExtracting = false
        }
    }
}
