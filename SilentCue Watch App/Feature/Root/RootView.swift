import SwiftUI
import ComposableArchitecture

struct RootView: View {
    let store: StoreOf<RootFeature>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                TimerStartView(
                    store: store.scope(
                        state: \.timerStartState,
                        action: RootFeature.Action.timerStart
                    )
                )
                .navigationDestination(
                    isPresented: Binding(
                        get: { viewStore.currentScreen == .countdown },
                        set: { if !$0 { viewStore.send(.navigateTo(.timerStart)) } }
                    )
                ) {
                    CountdownView(
                        store: store.scope(
                            state: \.countdownState,
                            action: RootFeature.Action.countdown
                        )
                    )
                }
                .navigationDestination(
                    isPresented: Binding(
                        get: { viewStore.currentScreen == .settings },
                        set: { if !$0 { viewStore.send(.navigateTo(.timerStart)) } }
                    )
                ) {
                    SettingsView(
                        store: store.scope(
                            state: \.settingsState,
                            action: RootFeature.Action.settings
                        )
                    )
                }
            }
        }
    }
} 