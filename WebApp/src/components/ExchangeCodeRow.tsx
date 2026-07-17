import { useState } from 'react'
import { Copy } from 'lucide-react'
import type { ExchangeCode } from '../types'
import { cn } from '../lib/utils'

interface ExchangeCodeRowProps {
  code: ExchangeCode
}

export function ExchangeCodeRow({ code }: ExchangeCodeRowProps) {
  const [copied, setCopied] = useState(false)

  const handleCopy = () => {
    navigator.clipboard.writeText(code.code).catch(() => {})
    setCopied(true)
    setTimeout(() => setCopied(false), 2000)
  }

  return (
    <div className="flex items-center gap-3 py-3 px-4">
      {/* Bullet */}
      <div className={cn(
        'w-2.5 h-2.5 rounded-full flex-shrink-0',
        code.isNew ? 'bg-[#FF6EB4]' : 'bg-[#2C2555]/25'
      )} />

      {/* Code + description */}
      <div className="flex-1 min-w-0">
        <p className="text-[15px] font-black text-[#2C2555] tracking-wider font-mono">
          {code.code}
        </p>
        <p className="text-[12px] text-[#2C2555]/40 mt-0.5 truncate">{code.description}</p>
      </div>

      {/* Action buttons */}
      <div className="flex items-center gap-2 flex-shrink-0">
        <button
          onClick={handleCopy}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl border-[1.5px] border-[#2C2555]/15 text-[12px] font-semibold text-[#2C2555]/55 bg-white transition-colors hover:border-[#2C2555]/30"
        >
          <Copy size={11} strokeWidth={2.5} />
          {copied ? '已复制' : '复制'}
        </button>
        <button
          className="px-3.5 py-1.5 rounded-xl text-[12px] font-bold text-white"
          style={{ background: 'linear-gradient(135deg, #FF6EB4, #e0488a)' }}
        >
          兑换
        </button>
      </div>
    </div>
  )
}
