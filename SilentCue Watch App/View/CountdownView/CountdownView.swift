import ComposableArchitecture
import SCShared
import SwiftUI

struct CountdownView: View {
    let store: StoreOf<TimerReducer>

    var body: some View {
        WithViewStore(store, observe: { $0 }, content: { viewStore in
            VStack {
                Spacer()

                TimeDisplayView(displayTime: viewStore.displayTime, remainingSeconds: viewStore.currentRemainingSeconds
                ).accessibilityIdentifier(SCAccessibilityIdentifiers.CountdownView.countdownTimeDisplay.rawValue)

                Spacer()

                CancelButtonView {
                    viewStore.send(.cancelTimer)
                }.accessibilityIdentifier(SCAccessibilityIdentifiers.CountdownView.cancelTimerButton.rawValue)
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                if viewStore.isRunning {
                    viewStore.send(.updateTimerDisplay)
                }
            }
        })
    }
}
