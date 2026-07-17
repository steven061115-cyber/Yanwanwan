import { Bell, BookmarkCheck, Clock, Plus, RefreshCw, Star } from 'lucide-react'
import { cn } from '../lib/utils'
import type { Game } from '../types'

interface SettingsViewProps {
  games: Game[]
  notifEnabled: boolean
  onToggleNotif: () => void
  reminderTime: string
  onReminderChange: (v: string) => void
}

export function SettingsView({
  games,
  notifEnabled,
  onToggleNotif,
  reminderTime,
  onReminderChange,
}: SettingsViewProps) {
  return (
    <div className="flex flex-col h-full bg-[#FDF0F8] overflow-y-auto pb-28">
      <div className="px-4 pt-5 space-y-5">

        {/* Settings header card */}
        <div
          className="relative rounded-[20px] overflow-hidden border border-white/15"
          style={{
            background: 'linear-gradient(135deg, #4A72C4, #6B5EA8)',
            boxShadow: '0 6px 24px rgba(74,114,196,0.30)',
          }}
        >
          <div className="flex items-center gap-3.5 p-4">
            <div className="w-14 h-14 rounded-[16px] bg-white/90 flex items-center justify-center shadow-md flex-shrink-0">
              <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#4A72C4" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/>
                <circle cx="12" cy="12" r="3"/>
              </svg>
            </div>
            <div>
              <p className="text-white font-black text-xl leading-tight">内务设置</p>
              <p className="text-white/70 text-[11px] font-semibold tracking-[0.8px] mt-1">
                小的按您的规矩办
              </p>
            </div>
          </div>
          {/* Star decoration */}
          <Star size={14} fill="#FFD95A" strokeWidth={0} className="absolute top-3.5 right-3.5 text-[#FFD95A]" />
        </div>

        {/* 关注的游戏 */}
        <SectionLabel icon={<BookmarkCheck size={13} strokeWidth={2.5} />} iconBg="#FF6EB4" title="关注的游戏" />
        <div
          className="bg-white rounded-[18px] border-[1.5px] border-[#2C2555]/10 overflow-hidden"
          style={{ boxShadow: '0 3px 12px rgba(44,37,85,0.06)' }}
        >
          {games.map((game, idx) => (
            <div key={game.id}>
              {idx > 0 && <div className="h-px bg-[#2C2555]/06 mx-4" />}
              <div className="flex items-center gap-3 px-4 py-3">
                <div
                  className="w-11 h-11 rounded-[12px] flex items-center justify-center text-xl flex-shrink-0"
                  style={{ backgroundColor: `${game.headerColor}22` }}
                >
                  {game.emoji}
                </div>
                <span className="flex-1 text-[15px] font-semibold text-[#2C2555]">{game.name}</span>
                <button className="w-7 h-7 rounded-full border-[1.5px] border-[#2C2555]/20 flex items-center justify-center">
                  <svg width="10" height="10" viewBox="0 0 10 10" fill="none">
                    <path d="M2 2l6 6M8 2l-6 6" stroke="#2C2555" strokeOpacity="0.4" strokeWidth="1.7" strokeLinecap="round"/>
                  </svg>
                </button>
              </div>
            </div>
          ))}
        </div>

        {/* 自定义游戏 */}
        <SectionLabel icon={<Plus size={13} strokeWidth={2.5} />} iconBg="#E8895A" title="自定义游戏" />
        <button
          className={cn(
            'w-full flex items-center justify-center gap-2.5 py-4 rounded-[18px]',
            'border border-white/20'
          )}
          style={{
            background: 'linear-gradient(135deg, #FF6EB4, #FF4DA6)',
            boxShadow: '0 4px 14px rgba(255,110,180,0.40)',
          }}
        >
          <div className="w-8 h-8 rounded-full bg-white/25 flex items-center justify-center flex-shrink-0">
            <Plus size={14} strokeWidth={3} className="text-white" />
          </div>
          <span className="text-white font-black text-base">添加要盯的游戏</span>
          <Star size={11} fill="#FFD95A" strokeWidth={0} className="text-[#FFD95A]" />
        </button>
        <p className="text-center text-xs text-[#2C2555]/35 -mt-3">小的可联网帮您整理自定义游戏活动</p>

        {/* 通知设置 */}
        <SectionLabel icon={<Bell size={13} strokeWidth={2.5} />} iconBg="#FFD95A" title="通知设置" />
        <div
          className="bg-white rounded-[18px] border-[1.5px] border-[#2C2555]/10 overflow-hidden"
          style={{ boxShadow: '0 3px 12px rgba(44,37,85,0.06)' }}
        >
          {/* 通知状态 */}
          <div className="flex items-center gap-3 px-4 py-3.5">
            <div className="w-10 h-10 rounded-[12px] bg-[#FF6EB4] flex items-center justify-center flex-shrink-0">
              <Bell size={16} strokeWidth={2.5} className="text-white" />
            </div>
            <div className="flex-1">
              <p className="text-[15px] font-semibold text-[#2C2555]">通知状态</p>
              <p className={cn('text-xs mt-0.5', notifEnabled ? 'text-[#39C5BB]' : 'text-red-400')}>
                {notifEnabled ? '✓ 已开启' : '已关闭'}
              </p>
            </div>
            <Toggle enabled={notifEnabled} onChange={onToggleNotif} />
          </div>

          <div className="h-px bg-[#2C2555]/06 mx-4" />

          {/* 每日打卡提醒 */}
          <div className="flex items-center gap-3 px-4 py-3.5">
            <div className="w-10 h-10 rounded-[12px] bg-[#FFD95A] flex items-center justify-center flex-shrink-0">
              <Clock size={16} strokeWidth={2.5} className="text-[#2C2555]" />
            </div>
            <div className="flex-1">
              <p className="text-[15px] font-semibold text-[#2C2555]">每日禀报</p>
              <p className="text-xs text-[#2C2555]/45 mt-0.5">{reminderTime} 每天</p>
            </div>
            <input
              type="time"
              value={reminderTime}
              onChange={e => onReminderChange(e.target.value)}
              className="text-sm font-semibold text-[#2C2555] bg-transparent border-none outline-none cursor-pointer"
            />
          </div>

          <div className="h-px bg-[#2C2555]/06 mx-4" />

          {/* 通知规则 */}
          <div className="flex items-center px-4 py-3.5">
            <span className="text-sm font-semibold text-[#2C2555]/55 flex-1">通知规则</span>
            <svg width="7" height="12" viewBox="0 0 7 12" fill="none">
              <path d="M1 1l5 5-5 5" stroke="#2C2555" strokeOpacity="0.25" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </div>
        </div>

        {/* 数据 */}
        <SectionLabel icon={<RefreshCw size={13} strokeWidth={2.5} />} iconBg="#39C5BB" title="数据" />
        <div
          className="bg-white rounded-[18px] border-[1.5px] border-[#2C2555]/10 overflow-hidden"
          style={{ boxShadow: '0 3px 12px rgba(44,37,85,0.06)' }}
        >
          <div className="flex items-center px-4 py-3.5">
            <span className="text-sm font-semibold text-[#2C2555]/55 flex-1">数据来源</span>
            <span className="text-sm text-[#2C2555]/40">api.ennead.cc</span>
          </div>
          <div className="h-px bg-[#2C2555]/06 mx-4" />
          <button className="w-full flex items-center justify-center gap-2 py-3.5 text-[#FF6EB4] font-semibold text-sm">
            <RefreshCw size={13} strokeWidth={2.5} />
            立即清点数据
          </button>
        </div>

        <p className="text-center text-[11px] text-[#2C2555]/30 pb-2">
          此 App 使用社区第三方 API 获取活动数据，与米哈游官方无关。
        </p>
      </div>
    </div>
  )
}

// MARK: - Sub-components

function SectionLabel({ icon, iconBg, title }: { icon: React.ReactNode; iconBg: string; title: string }) {
  return (
    <div className="flex items-center gap-2 px-1">
      <div
        className="w-[26px] h-[26px] rounded-[7px] flex items-center justify-center text-white flex-shrink-0"
        style={{ backgroundColor: iconBg }}
      >
        {icon}
      </div>
      <span className="text-[15px] font-bold text-[#2C2555]">{title}</span>
    </div>
  )
}

function Toggle({ enabled, onChange }: { enabled: boolean; onChange: () => void }) {
  return (
    <button
      role="switch"
      aria-checked={enabled}
      onClick={onChange}
      className={cn(
        'relative w-12 h-7 rounded-full transition-colors duration-200 flex-shrink-0',
        enabled ? 'bg-[#FF6EB4]' : 'bg-[#2C2555]/20'
      )}
    >
      <span
        className={cn(
          'absolute top-[3px] w-[22px] h-[22px] bg-white rounded-full shadow transition-transform duration-200',
          enabled ? 'translate-x-[22px]' : 'translate-x-[3px]'
        )}
      />
    </button>
  )
}
