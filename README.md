# SilentCue - Silent Timer App for Apple Watch

## Project Overview

SilentCue is a silent timer app for Apple Watch that notifies you with haptic feedback instead of sound alerts. It's perfect for use in meetings or quiet environments where audio notifications would be disruptive.

The app offers a simple interface optimized for the compact Apple Watch screen, allowing you to easily set timers and choose vibration patterns. Built with The Composable Architecture (TCA), it ensures stable operation and maintainability. The app is optimized for Apple Watch Series 10 and watchOS 11.2.

## Architecture

This project uses The Composable Architecture (TCA 1.19.0) to provide a consistent method for state management and UI updates:

```
State → Action → Reducer → Effect → State (updated)
```

- **State**: Represents the app's state
- **Action**: Represents user operations or system events
- **Reducer**: Generates new state based on current state and actions
- **Effect**: Represents asynchronous processing and side effects
- **Store**: Central hub that holds state and dispatches actions

### Navigation

The app uses SwiftUI's `NavigationStack` for smooth screen transitions with animations:

```swift
NavigationStack {
    TimerStartView(store: timerStartStore)
        .navigationDestination(isPresented: $showsCountdown) {
            CountdownView(store: countdownStore)
        }
        .navigationDestination(isPresented: $showsSettings) {
            SettingsView(store: settingsStore)
        }
}
```

This approach provides:
1. **Smooth transitions**: Screens slide in and out with natural animation
2. **Automatic back button**: Navigation bar automatically includes back buttons
3. **Accessibility**: Standard navigation patterns enhance usability
4. **Maintainability**: Uses SwiftUI's built-in navigation patterns

### Dependency Injection

The project leverages TCA's dependency injection system to manage external dependencies:

```swift
// Define a dependency 
extension DependencyValues {
    var userDefaultsManager: UserDefaultsManager {
        get { self[UserDefaultsManagerKey.self] }
        set { self[UserDefaultsManagerKey.self] = newValue }
    }
}

// Use the dependency in a reducer
struct MyFeature: Reducer {
    @Dependency(\.userDefaultsManager) var userDefaultsManager
    
    // Access the dependency in effects
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            // ...
            return .run { _ in
                let value = self.userDefaultsManager.object(forKey: .someKey)
                // ...
            }
        }
    }
}
```

This approach offers several benefits:
1. **Testability**: Dependencies can be easily mocked in tests
2. **Modularity**: Features access only the dependencies they need
3. **Consistency**: Dependencies are accessed the same way throughout the app
4. **Control**: External services are accessed through well-defined interfaces

### Store Management

In TCA, the `Store` is a crucial component that maintains application state and coordinates actions. In our architecture:

- The root `Store` is instantiated in `SilentCueApp.swift` as the app's entry point:
  ```swift
  let store: StoreOf<RootFeature> = Store(initialState: RootFeature.State()) {
      RootFeature()
  }
  ```

- This root store manages the entire app state through the root reducer, which combines all feature reducers
- Child stores for individual features are derived from the root store using the `.scope()` method
- Each view receives only the portion of state and actions it needs to function

This approach follows the TCA pattern of having a single source of truth (the root store) while allowing components to access only the state they need, preventing unnecessary re-renders and maintaining a clean architecture.

### Feature-Based Organization

The project follows a feature-based directory structure where each feature has its own directory containing exactly one View file and one Feature file (containing the reducer):

```
Feature/
└── FeatureName/
    ├── FeatureNameFeature.swift  // Contains State, Action, and Reducer
    └── FeatureNameView.swift     // Contains the SwiftUI View
```

This 1:1 pairing of View and Feature files serves several purposes:

1. **Modularity**: Each feature is a self-contained unit with clear boundaries
2. **Separation of Concerns**: UI logic (View) is kept separate from business logic (Feature)
3. **Discoverability**: Related files are grouped together, making the codebase easier to navigate
4. **Scalability**: New features can be added as independent modules without modifying existing code
5. **Testability**: Each feature's business logic can be tested in isolation

The reducer in each Feature file defines how the state changes in response to actions, while the View file defines how the state is rendered and how user interactions are translated into actions.

## Apple Watch Series 10 Optimizations

The app has been optimized for Apple Watch Series 10 and watchOS 11.2:

1. **Safe Haptic Feedback**: Uses compatible WKHapticType members for vibration patterns
2. **Swift 6 Compatibility**: Complies with Swift 6 rules for handling inout parameters in concurrent code
3. **Modern TCA API**: Uses the latest TCA 1.19.0 APIs including forEach and Scope for child reducers
4. **Improved Navigation**: Uses NavigationStack for smooth, animated transitions

## Directory Structure

```
SilentCue Watch App/
├── Feature/
│   ├── Root/
│   │   ├── RootFeature.swift
│   │   └── RootView.swift
│   ├── TimerStart/
│   │   ├── TimerStartFeature.swift
│   │   └── TimerStartView.swift
│   ├── Countdown/
│   │   ├── CountdownFeature.swift
│   │   └── CountdownView.swift
│   └── Settings/
│       ├── SettingsFeature.swift
│       └── SettingsView.swift
├── Model/
│   └── HapticType.swift
├── Service/
│   ├── UserDefaultsManager.swift
│   └── UserDefaultsDependency.swift
├── Util/
│   └── TimeFormatter.swift
└── SilentCueApp.swift
```

### Directory Responsibilities

- **Feature/**: Contains feature modules, each with its own reducer and view. The core of the application's functionality.
  - **Root/**: Manages navigation between features and orchestrates the overall app flow
  - **TimerStart/**: Handles the timer setup screen with hour/minute selection
  - **Countdown/**: Manages the countdown timer and haptic feedback
  - **Settings/**: Controls user preferences for haptic feedback types and behaviors

- **Model/**: Contains domain models and data structures used throughout the app.
  - Includes enums like `HapticType` that represent core concepts in the domain

- **Service/**: Contains reusable services that interface with system frameworks or provide app-wide functionality.
  - Includes the `UserDefaultsManager` for persistent storage
  - Also contains dependency wrappers like `UserDefaultsDependency` for TCA integration

- **Util/**: Contains utility functions and extensions that are used across multiple features.
  - Includes helpers like time formatting functions in a namespace

## Technology Stack

- **Swift** and **SwiftUI** for UI development
- **The Composable Architecture 1.19.0** for state management and business logic separation
- **NavigationStack** for smooth screen transitions
- **WatchKit** for native watchOS features
- **UserDefaults** for settings persistence

## Key Features

### Intuitive Timer Setting
Provides an interface for easily selecting hours and minutes to start a timer immediately. The simple design allows for quick operation even on a small screen.

### Smooth Navigation
Uses SwiftUI's NavigationStack for fluid, animated transitions between screens, providing a more polished user experience.

### Countdown Display
Visually displays the countdown from the set time. When the remaining time is less than 1 minute, it changes color to red for added visibility.

### Haptic Feedback
Choose from various haptic patterns for timer completion. Select from notification, success, and other vibration patterns to customize feedback based on your situation.

### Customizable Settings
Customize settings such as vibration type and auto-stop feature according to user preferences. Settings are automatically saved and reflected in subsequent uses.

### Background Execution
The timer continues to run accurately even after sending the app to the background, notifying you with vibration when the set time has elapsed.

## Usage

1. Launch the app and set hours and minutes on the main screen
2. Tap the "Start Timer" button to begin countdown
3. The countdown screen shows the remaining time; stop the timer with the "Cancel" button if needed
4. Access settings by tapping the gear icon, and customize vibration patterns and auto-stop functionality
5. Navigate between screens using the intuitive swipe gestures or the back button in the navigation bar 