import { useState, useCallback } from 'react'
import { ActivityView } from './components/ActivityView'
import { SettingsView } from './components/SettingsView'
import { GameDetailPage } from './components/GameDetailPage'
import { EventGuidePage } from './components/EventGuidePage'
import { FloatingTabBar, type Tab } from './components/FloatingTabBar'
import { mockGames } from './data/mockData'
import type { Game, NavigationState } from './types'

export default function App() {
  const [activeTab, setActiveTab] = useState<Tab>('activity')
  const [nav, setNav] = useState<NavigationState>({ page: 'activity' })
  const [games, setGames] = useState<Game[]>(mockGames)
  const [notifEnabled, setNotifEnabled] = useState(true)
  const [reminderTime, setReminderTime] = useState('08:00')

  const handleToggleDone = useCallback((gameId: string, eventId: string) => {
    setGames(prev =>
      prev.map(game =>
        game.id !== gameId ? game : {
          ...game,
          events: game.events.map(ev =>
            ev.id !== eventId ? ev : { ...ev, isDone: !ev.isDone }
          ),
        }
      )
    )
  }, [])

  // Tab change resets to root page of that tab
  const handleTabChange = (tab: Tab) => {
    setActiveTab(tab)
    setNav({ page: tab === 'activity' ? 'activity' : 'settings' })
  }

  const handleGameClick = (gameId: string) => {
    setNav({ page: 'game-detail', gameId })
  }

  const handleEventClick = (gameId: string, eventId: string) => {
    setNav({ page: 'event-guide', gameId, eventId })
  }

  // Determine whether to show the floating tab bar
  const showTabBar = nav.page === 'activity' || nav.page === 'settings'

  // Find current game/event for detail pages
  const currentGame = nav.page === 'game-detail' || nav.page === 'event-guide'
    ? games.find(g => g.id === nav.gameId)
    : undefined

  const currentEvent = nav.page === 'event-guide' && currentGame
    ? currentGame.events.find(e => e.id === nav.eventId)
    : undefined

  return (
    <div className="relative h-full max-w-[430px] mx-auto bg-[#FDF0F8] overflow-hidden">
      {/* Polka dot background */}
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          backgroundImage: `radial-gradient(circle, rgba(44,37,85,0.05) 1px, transparent 1px)`,
          backgroundSize: '24px 24px',
        }}
      />

      <div className="relative h-full">
        {nav.page === 'activity' && (
          <ActivityView games={games} onGameClick={handleGameClick} />
        )}

        {nav.page === 'settings' && (
          <SettingsView
            games={games}
            notifEnabled={notifEnabled}
            onToggleNotif={() => setNotifEnabled(p => !p)}
            reminderTime={reminderTime}
            onReminderChange={setReminderTime}
          />
        )}

        {nav.page === 'game-detail' && currentGame && (
          <GameDetailPage
            game={currentGame}
            onBack={() => setNav({ page: 'activity' })}
            onEventClick={(eventId) => handleEventClick(currentGame.id, eventId)}
            onToggleDone={handleToggleDone}
          />
        )}

        {nav.page === 'event-guide' && currentGame && currentEvent && (
          <EventGuidePage
            game={currentGame}
            event={currentEvent}
            onBack={() => setNav({ page: 'game-detail', gameId: currentGame.id })}
            onToggleDone={handleToggleDone}
          />
        )}
      </div>

      {showTabBar && (
        <FloatingTabBar activeTab={activeTab} onChange={handleTabChange} />
      )}
    </div>
  )
}
