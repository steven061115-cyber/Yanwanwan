import { cn, formatRemaining } from '../lib/utils'
import { Zap, Clock, ChevronRight } from 'lucide-react'
import { getUrgency, type Game } from '../types'

interface GameBoardProps {
  game: Game
  onClick: (gameId: string) => void
}

export function GameBoard({ game, onClick }: GameBoardProps) {
  const now = Math.floor(Date.now() / 1000)

  const activeEvents = game.events
    .filter(e => !e.isDone && e.endTimestamp > now)
    .sort((a, b) => a.endTimestamp - b.endTimestamp)

  const topEvents = activeEvents.slice(0, 2)
  const activeCount = activeEvents.length

  return (
    <button
      onClick={() => onClick(game.id)}
      className="w-full text-left rounded-[20px] overflow-hidden border-[1.5px] border-[#2C2555]/20 active:scale-[0.98] transition-transform"
      style={{ boxShadow: `0 6px 24px ${game.headerColor}38` }}
    >
      {/* Header */}
      <div
        className="flex items-center gap-3 px-3.5 py-3"
        style={{ backgroundColor: game.headerColor }}
      >
        <div className="w-[52px] h-[52px] rounded-[14px] bg-white/90 flex items-center justify-center flex-shrink-0 shadow-md">
          <span className="text-2xl leading-none">{game.emoji}</span>
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-white font-black text-[18px] leading-tight truncate">{game.name}</p>
          <p className="text-white/70 text-[11px] font-semibold tracking-[0.8px] mt-0.5">
            QUEST BOARD · 进行中
          </p>
        </div>
        <div className="flex items-center gap-1.5 flex-shrink-0">
          <div className="flex items-center gap-1 bg-[#FFD95A] rounded-full px-2.5 py-1.5">
            <Zap size={10} strokeWidth={3} className="text-[#2C2555]" />
            <span className="text-[12px] font-bold text-[#2C2555]">{activeCount} 个活动</span>
          </div>
          <ChevronRight size={16} strokeWidth={3} className="text-white/60" />
        </div>
      </div>

      {/* Body */}
      <div className="bg-white px-3 py-2">
        {topEvents.length > 0 ? (
          <div className="space-y-0">
            {topEvents.map((event, idx) => {
              const remaining = event.endTimestamp - now
              const urgency = getUrgency(remaining, event.isDone)
              const isUrgent = urgency === 'critical' || urgency === 'warning'
              const pillBg = isUrgent ? 'bg-[#FF6EB4] text-white' : 'bg-[#FFD95A] text-[#2C2555]'
              const iconBg = isUrgent ? 'bg-[#FF6EB4]/12' : `bg-[${game.accentColor}]/10`

              return (
                <div key={event.id}>
                  {idx > 0 && <div className="h-px bg-[#2C2555]/06 mx-1" />}
                  <div className="flex items-center gap-2.5 py-2.5 px-1">
                    {/* Left accent bar */}
                    <div
                      className="w-1 h-8 rounded-full flex-shrink-0"
                      style={{ backgroundColor: game.headerColor }}
                    />
                    {/* Icon */}
                    <div
                      className={cn('w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0')}
                      style={{
                        backgroundColor: isUrgent ? 'rgba(255,110,180,0.12)' : `${game.headerColor}18`
                      }}
                    >
                      <span
                        className={cn('font-black', isUrgent ? 'text-sm text-[#FF6EB4]' : 'text-[9px]')}
                        style={!isUrgent ? { color: game.headerColor } : {}}
                      >
                        {isUrgent ? '!' : '▶'}
                      </span>
                    </div>
                    {/* Title */}
                    <span className="flex-1 text-[14px] font-semibold text-[#2C2555] truncate">
                      {event.title}
                    </span>
                    {/* Pill */}
                    <div className={cn('flex items-center gap-1 px-2.5 py-1.5 rounded-full text-[12px] font-bold flex-shrink-0', pillBg)}>
                      <Clock size={10} strokeWidth={2.5} />
                      <span>{formatRemaining(remaining)}</span>
                    </div>
                  </div>
                </div>
              )
            })}
          </div>
        ) : (
          <p className="text-center text-[13px] text-[#2C2555]/35 py-4">
            本轮暂且清闲，您可歇会儿 🎉
          </p>
        )}
      </div>
    </button>
  )
}
