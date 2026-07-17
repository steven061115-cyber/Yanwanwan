import { cn, formatRemaining } from '../lib/utils'
import { getUrgency, type GameEvent } from '../types'
import { Clock } from 'lucide-react'

interface EventRowProps {
  event: GameEvent
  headerColor: string
  onToggleDone: (id: string) => void
  onClick?: (id: string) => void
}

export function EventRow({ event, headerColor, onToggleDone, onClick }: EventRowProps) {
  const remaining = event.endTimestamp - Math.floor(Date.now() / 1000)
  const urgency = getUrgency(remaining, event.isDone)
  const isUrgent = urgency === 'critical' || urgency === 'warning'
  const isExpired = urgency === 'expired'
  const isDone = urgency === 'done'

  // End date label
  const endDate = new Date(event.endTimestamp * 1000)
  const endLabel = `${endDate.getMonth() + 1}月${endDate.getDate()}日结束`

  const pillBg = isDone || isExpired
    ? 'bg-gray-100 text-gray-400'
    : isUrgent
      ? 'bg-[#FF6EB4] text-white'
      : 'bg-[#FFD95A] text-[#2C2555]'

  const iconBg = isDone || isExpired
    ? 'bg-[#2C2555]/08'
    : isUrgent
      ? 'bg-[#FF6EB4]'
      : 'bg-[#DDB4F0]/60'

  const iconColor = isDone || isExpired ? '#999' : isUrgent ? 'white' : headerColor

  const borderColor = isDone || isExpired
    ? 'border-[#2C2555]/08'
    : isUrgent
      ? 'border-[#FF6EB4]/30'
      : 'border-[#DDB4F0]/50'

  return (
    <div
      className={cn(
        'flex items-center gap-3 p-3 rounded-2xl border-[1.5px] bg-white cursor-pointer',
        'active:scale-[0.98] transition-transform',
        borderColor,
        (isDone || isExpired) && 'opacity-55'
      )}
      onClick={() => onClick?.(event.id)}
    >
      {/* Square icon */}
      <div
        className={cn('w-10 h-10 rounded-[12px] flex items-center justify-center flex-shrink-0', iconBg)}
      >
        {isDone ? (
          <span className="text-sm font-black" style={{ color: '#39C5BB' }}>✓</span>
        ) : isExpired ? (
          <span className="text-sm font-black text-gray-400">✕</span>
        ) : isUrgent ? (
          <span className="text-base font-black text-white">!</span>
        ) : (
          <span className="text-[10px] font-black" style={{ color: iconColor }}>▶</span>
        )}
      </div>

      {/* Title + meta */}
      <div className="flex-1 min-w-0">
        <p className={cn(
          'text-[14px] font-bold text-[#2C2555] leading-snug truncate',
          isDone && 'line-through opacity-40'
        )}>
          {event.title}
        </p>
        {!isDone && (
          <p className="text-[12px] text-[#2C2555]/40 mt-0.5">
            {endLabel} · {event.category}
          </p>
        )}
      </div>

      {/* Countdown pill */}
      <div className={cn('flex items-center gap-1 px-2.5 py-1.5 rounded-full text-[12px] font-bold flex-shrink-0', pillBg)}>
        <Clock size={10} strokeWidth={2.5} />
        <span>{formatRemaining(remaining)}</span>
      </div>

      {/* Done toggle */}
      <button
        onClick={(e) => { e.stopPropagation(); onToggleDone(event.id) }}
        className="flex-shrink-0"
        aria-label={isDone ? '标记为未完成' : '标记为完成'}
      >
        <div className={cn(
          'w-5 h-5 rounded-full border-[1.5px] flex items-center justify-center transition-all',
          isDone ? 'bg-[#39C5BB] border-[#39C5BB]' : 'border-[#2C2555]/20'
        )}>
          {isDone && <span className="text-[9px] font-black text-white">✓</span>}
        </div>
      </button>
    </div>
  )
}
