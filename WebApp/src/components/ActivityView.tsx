import { GameBoard } from './GameBoard'
import { formatTodayLabel } from '../lib/utils'
import { HelpCircle, Plus, Star } from 'lucide-react'
import type { Game } from '../types'

interface ActivityViewProps {
  games: Game[]
  onGameClick: (gameId: string) => void
}

export function ActivityView({ games, onGameClick }: ActivityViewProps) {
  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="px-4 pt-5 pb-3 bg-[#FDF0F8]">
        <div className="flex items-start justify-between">
          <div className="flex flex-col gap-1">
            <h1 className="text-[26px] font-black text-[#2C2555] leading-tight">
              皇上请阅奏折
            </h1>
            <div className="h-[3px] rounded-full bg-[#FF6EB4] mr-10" />
          </div>
          <div className="flex items-center gap-2.5 mt-0.5">
            <button
              className="w-9 h-9 rounded-full bg-white border-[1.5px] border-[#2C2555]/25 flex items-center justify-center"
              style={{ boxShadow: '0 2px 8px rgba(44,37,85,0.10)' }}
            >
              <HelpCircle size={15} strokeWidth={2.5} className="text-[#2C2555]" />
            </button>
            <button
              className="w-9 h-9 rounded-[10px] flex items-center justify-center"
              style={{ background: '#FF6EB4', boxShadow: '0 3px 10px rgba(255,110,180,0.40)' }}
            >
              <Plus size={16} strokeWidth={3} className="text-white" />
            </button>
          </div>
        </div>
        {/* Date badge */}
        <div className="mt-3 inline-flex items-center gap-1.5 bg-[#2C2555] rounded-full px-3.5 py-1.5">
          <Star size={11} strokeWidth={0} fill="#FFD95A" className="text-[#FFD95A]" />
          <span className="text-white text-[13px] font-extrabold">{formatTodayLabel()}</span>
        </div>
      </div>

      {/* Scrollable boards */}
      <div className="flex-1 overflow-y-auto px-4 pb-28 bg-[#FDF0F8]">
        <div className="space-y-4 pt-3">
          {games.map(game => (
            <GameBoard key={game.id} game={game} onClick={onGameClick} />
          ))}
          <p className="text-center text-xs font-semibold text-[#FF6EB4]/35 pt-1 pb-4">
            ✦ 以上就是小的今日呈报 ✦
          </p>
        </div>
      </div>
    </div>
  )
}
