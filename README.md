# SilentCue - Silent Timer App for Apple Watch

## Project Overview

SilentCue is a silent timer app for Apple Watch that notifies you with haptic feedback instead of sound alerts. It's perfect for use in meetings or quiet environments where audio notifications would be disruptive.

The app offers a simple interface optimized for the compact Apple Watch screen, allowing you to easily set timers and choose vibration patterns. Built with The Composable Architecture (TCA), it ensures stable operation and maintainability. The app is optimized for Apple Watch Series 10 and watchOS 11.2.

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

## Architecture

This project uses a simplified version of The Composable Architecture (TCA 1.19.0) focusing on independent features without a complex global state hierarchy:

```
[Feature-Specific State] → [Feature-Specific Action] → [Feature-Specific Reducer] → [Effect] → [Updated State]
```

The app has been refactored to remove unnecessary complexity, emphasizing a lightweight, pragmatic approach to TCA:

- **Focused Features**: Each feature (Timer, Settings) maintains its own state and logic
- **Direct Navigation**: Uses SwiftUI's native NavigationStack and callbacks for navigation
- **Minimal State Management**: No global state container, just feature-specific stores
- **Simplified Communication**: Features communicate via callbacks instead of complex action routing

### Navigation

The app uses SwiftUI's `NavigationStack` with NavigationPath for declarative navigation:

```swift
NavigationStack(path: $navPath) {
    TimerStartView(
        store: timerStore,
        onSettingsButtonTapped: {
            navPath.append(AppScreen.settings)
        },
        onTimerStart: {
            navPath.append(AppScreen.countdown)
        }
    )
    .navigationDestination(for: AppScreen.self) { screen in
        switch screen {
        case .countdown:
            CountdownView(store: timerStore, onCancel: { ... })
        case .settings:
            SettingsView(store: settingsStore)
        // ...
        }
    }
}
```

This approach provides:
1. **Native Animation**: Uses SwiftUI's built-in transitions for smooth movement
2. **Type-Safe Navigation**: Destinations are tied to specific enum cases
3. **Declarative Routing**: Screen flow is described with a clear navigation path
4. **Simpler State Management**: Navigation state is managed with SwiftUI rather than TCA

### Store Management

The application now uses independent feature-specific stores instead of a complex hierarchy:

```swift
// Independent stores are created directly in the app entry point
let timerStore = Store(initialState: TimerState()) {
    TimerReducer()
}

let settingsStore = Store(initialState: SettingsState()) {
    SettingsReducer()
}
```

Benefits of this approach:
1. **Reduced Complexity**: No need for complex scoping or action mapping
2. **Independence**: Features operate independently without unnecessary coupling
3. **Performance**: Each feature manages only its own state, minimizing rendering
4. **Simplicity**: Easier to understand, maintain, and extend the codebase

### Dependency Injection

The project still leverages TCA's dependency injection system for external dependencies:

```swift
// Define a dependency 
extension DependencyValues {
    var userDefaultsManager: UserDefaultsManager {
        get { self[UserDefaultsManagerKey.self] }
        set { self[UserDefaultsManagerKey.self] = newValue }
    }
}

// Use the dependency in a reducer
struct SettingsReducer: Reducer {
    @Dependency(\.userDefaultsManager) var userDefaultsManager
    
    // Access the dependency in effects
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            // ...
            return .run { _ in
                self.userDefaultsManager.set(value, forKey: .someKey)
                // ...
            }
        }
    }
}
```

### Project Structure

The project has been simplified to focus on the essential features:

```
SilentCue Watch App/
├── Domain/
│   ├── Timer/
│   │   ├── TimerAction.swift
│   │   ├── TimerReducer.swift
│   │   ├── TimerState.swift
│   │   └── TimerStore.swift
│   └── Settings/
│       ├── SettingsAction.swift
│       ├── SettingsReducer.swift
│       ├── SettingsState.swift
│       └── SettingsStore.swift
├── View/
│   ├── TimerStartView.swift
│   ├── CountdownView.swift
│   └── SettingsView.swift
├── Model/
│   └── HapticType.swift
├── StorageService/
│   ├── UserDefaultsManager.swift
│   └── UserDefaultsDependency.swift
├── Util/
│   └── TimeFormatter.swift
└── SilentCueApp.swift
```

### Key Architectural Decisions

1. **Removal of App Layer**: Eliminated the unnecessary App layer that added complexity without providing significant benefits
2. **Independent Feature Stores**: Each feature has its own store without complex hierarchy
3. **Native Navigation**: Using SwiftUI's navigation capabilities directly rather than managing navigation in TCA
4. **Callback-Based Communication**: Features communicate via simple callbacks rather than complex action routing
5. **Pragmatic TCA Usage**: Using TCA where it adds value (state management, effects, dependencies) but not where simpler solutions work better

## Apple Watch Series 10 Optimizations

The app has been optimized for Apple Watch Series 10 and watchOS 11.2:

1. **Safe Haptic Feedback**: Uses compatible WKHapticType members for vibration patterns
2. **Swift 6 Compatibility**: Complies with Swift 6 rules for handling inout parameters in concurrent code
3. **Modern TCA API**: Uses the latest TCA 1.19.0 APIs including @CasePathable macro for action handling
4. **Improved Navigation**: Uses NavigationStack with NavigationPath for smooth, animated transitions

## Technology Stack

- **Swift** and **SwiftUI** for UI development
- **The Composable Architecture 1.19.0** for state management and business logic separation
- **NavigationStack** for smooth screen transitions
- **WatchKit** for native watchOS features
- **UserDefaults** for settings persistence
