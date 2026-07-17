import { cn } from '../lib/utils'
import { Activity, Settings } from 'lucide-react'

export type Tab = 'activity' | 'settings'

interface FloatingTabBarProps {
  activeTab: Tab
  onChange: (tab: Tab) => void
}

interface TabItem {
  id: Tab
  label: string
  icon: React.ReactNode
}

const tabs: TabItem[] = [
  { id: 'activity', label: '活动', icon: <Activity size={16} strokeWidth={2.5} /> },
  { id: 'settings', label: '设置', icon: <Settings size={16} strokeWidth={2.5} /> },
]

export function FloatingTabBar({ activeTab, onChange }: FloatingTabBarProps) {
  return (
    <div className="fixed bottom-4 left-1/2 -translate-x-1/2 z-50 w-full max-w-[420px] px-8">
      <div
        className="flex items-center p-2 rounded-full bg-white border-[1.5px] border-[#2C2555]/10"
        style={{ boxShadow: '0 6px 24px rgba(44,37,85,0.18)' }}
      >
        {tabs.map(tab => {
          const isActive = activeTab === tab.id
          return (
            <button
              key={tab.id}
              onClick={() => onChange(tab.id)}
              className={cn(
                'flex items-center justify-center gap-1.5 rounded-full transition-all duration-300 font-bold text-sm',
                isActive
                  ? 'flex-1 py-3 px-6 text-white'
                  : 'w-12 h-12 text-[#2C2555]/40 hover:text-[#2C2555]/70'
              )}
              style={isActive ? {
                background: 'linear-gradient(135deg, #FF6EB4, #FF4DA6)',
                boxShadow: '0 4px 12px rgba(255,110,180,0.40)',
              } : {}}
            >
              {tab.icon}
              {isActive && <span>{tab.label}</span>}
            </button>
          )
        })}
      </div>
    </div>
  )
}
