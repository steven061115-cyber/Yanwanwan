import { ChevronLeft, Star, Calendar, ExternalLink } from 'lucide-react'
import { formatRemaining } from '../lib/utils'
import { getUrgency, type Game, type GameEvent } from '../types'
import { cn } from '../lib/utils'

interface EventGuidePageProps {
  game: Game
  event: GameEvent
  onBack: () => void
  onToggleDone: (gameId: string, eventId: string) => void
}

export function EventGuidePage({ game, event, onBack, onToggleDone }: EventGuidePageProps) {
  const remaining = event.endTimestamp - Math.floor(Date.now() / 1000)
  const urgency = getUrgency(remaining, event.isDone)
  const isUrgent = urgency === 'critical' || urgency === 'warning'

  const endDate = new Date(event.endTimestamp * 1000)
  const endLabel = `${endDate.getMonth() + 1}月${endDate.getDate()}日结束`
  const biliSearchUrl = `https://search.bilibili.com/all?keyword=${encodeURIComponent(event.title)}`

  return (
    <div className="flex flex-col h-full bg-[#FDF0F8]">
      {/* Nav bar */}
      <div className="flex items-center gap-3 px-4 pt-5 pb-4">
        <button
          onClick={onBack}
          className="w-10 h-10 rounded-[12px] bg-[#2C2555] flex items-center justify-center flex-shrink-0"
          style={{ boxShadow: '0 3px 10px rgba(44,37,85,0.25)' }}
        >
          <ChevronLeft size={20} strokeWidth={2.5} className="text-white" />
        </button>
        <span className="text-[18px] font-black text-[#2C2555]">活动攻略</span>
      </div>

      {/* Scrollable content */}
      <div className="flex-1 overflow-y-auto px-4 pb-32">
        <div className="space-y-4">

          {/* Hero card */}
          <div
            className="relative rounded-[20px] p-5 overflow-hidden border border-white/20"
            style={{
              background: isUrgent
                ? `linear-gradient(135deg, ${game.headerColor}, #39C5BB)`
                : `linear-gradient(135deg, ${game.headerColor}cc, #DDB4F0)`,
              boxShadow: `0 8px 28px ${game.headerColor}40`,
            }}
          >
            {/* Star bookmark */}
            <button className="absolute top-4 right-4">
              <Star size={18} strokeWidth={1.5} className="text-white/60" />
            </button>

            {/* Event title */}
            <p className="text-white/75 text-[13px] font-semibold mb-2">{event.title}</p>

            {/* Big countdown */}
            <p className="text-white font-black text-[36px] leading-none mb-4">
              {event.isDone ? '已完成' : remaining <= 0 ? '已结束' : `剩余 ${formatRemaining(remaining)}`}
            </p>

            {/* Badges */}
            <div className="flex items-center gap-2 flex-wrap">
              <div className="flex items-center gap-1.5 bg-white/20 rounded-full px-3 py-1.5">
                <Calendar size={12} strokeWidth={2} className="text-white" />
                <span className="text-white text-[12px] font-semibold">{endLabel}</span>
              </div>
              <div className="bg-white/20 rounded-full px-3 py-1.5">
                <span className="text-white text-[12px] font-semibold">{event.category}</span>
              </div>
            </div>

            {/* Heart decoration */}
            <span className="absolute bottom-3 right-4 text-white/20 text-2xl">♥</span>
          </div>

          {/* Bilibili card */}
          <a
            href={biliSearchUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-3 p-4 bg-white rounded-[18px] border-[1.5px] border-[#2C2555]/10 no-underline"
            style={{ boxShadow: '0 3px 12px rgba(44,37,85,0.06)' }}
          >
            {/* Bili logo */}
            <div className="w-12 h-12 rounded-[14px] flex items-center justify-center flex-shrink-0"
                 style={{ backgroundColor: '#00A1D6' }}>
              <span className="text-white font-black text-[13px] leading-none">bili</span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-[14px] font-bold text-[#2C2555]">在哔哩哔哩搜索攻略</p>
              <p className="text-[12px] text-[#2C2555]/40 mt-0.5 truncate">{event.title}</p>
            </div>
            <div className="w-9 h-9 rounded-[10px] flex items-center justify-center flex-shrink-0"
                 style={{ backgroundColor: '#DDB4F0/40', background: 'rgba(221,180,240,0.40)' }}>
              <ExternalLink size={15} strokeWidth={2} className="text-[#9B7BC7]" />
            </div>
          </a>

          {/* Event detail card */}
          <div
            className="bg-white rounded-[18px] border-[1.5px] border-[#2C2555]/10 overflow-hidden"
            style={{ boxShadow: '0 3px 12px rgba(44,37,85,0.06)' }}
          >
            <p className="text-[13px] font-bold text-[#2C2555] px-4 pt-4 pb-2">活动详情</p>
            {[
              { label: '所属游戏', value: game.name, color: false },
              { label: '活动类型', value: event.category, color: false },
              { label: '结束时间', value: endLabel, color: false },
              { label: '剩余时间', value: remaining > 0 ? formatRemaining(remaining) : '已结束', color: true },
            ].map((row, idx) => (
              <div key={row.label}>
                <div className="h-px bg-[#2C2555]/06 mx-4" />
                <div className="flex items-center px-4 py-3">
                  <span className="text-[13px] text-[#2C2555]/45 w-20 flex-shrink-0">{row.label}</span>
                  <span className={cn(
                    'text-[14px] font-semibold',
                    row.color && isUrgent ? 'text-[#FF6EB4]' : 'text-[#2C2555]'
                  )}>
                    {row.value}
                  </span>
                </div>
              </div>
            ))}
          </div>

        </div>
      </div>

      {/* Bottom action button */}
      <div className="absolute bottom-0 left-0 right-0 px-4 pb-6 pt-3"
           style={{ background: 'linear-gradient(to top, #FDF0F8 70%, transparent)' }}>
        <button
          onClick={() => onToggleDone(game.id, event.id)}
          className={cn(
            'w-full flex items-center justify-center gap-2.5 py-4 rounded-[18px]',
            'text-white font-black text-[16px] border border-white/20',
            'transition-all active:scale-[0.98]'
          )}
          style={event.isDone ? {
            background: 'linear-gradient(135deg, #39C5BB, #2aa99f)',
            boxShadow: '0 4px 16px rgba(57,197,187,0.35)',
          } : {
            background: 'linear-gradient(135deg, #FF6EB4, #FF4DA6)',
            boxShadow: '0 4px 16px rgba(255,110,180,0.40)',
          }}
        >
          <span>{event.isDone ? '↩' : '✓'}</span>
          <span>{event.isDone ? '标记为未完成' : '标记为已完成'}</span>
          {!event.isDone && (
            <Star size={13} fill="#FFD95A" strokeWidth={0} className="text-[#FFD95A]" />
          )}
        </button>
      </div>
    </div>
  )
}
