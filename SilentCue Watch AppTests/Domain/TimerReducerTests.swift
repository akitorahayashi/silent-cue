@testable import SilentCue_Watch_App
import ComposableArchitecture
import XCTest

@MainActor
final class TimerReducerTests: XCTestCase {
    func testMinutesSelection() async {
        let store = TestStore(
            initialState: AppState(),
            reducer: { AppReducer() }
        )

        await store.send(AppAction.timer(.minutesSelected(10))) { state in
            state.timer.selectedMinutes = 10
        }
        await store.finish()
    }
}
