import SwiftUI
import ComposableArchitecture

struct SettingsView: View {
    let store: StoreOf<SettingsReducer>
    
    // 表示用のデバッグフラグ
    @State private var showDebug = false
    
    // ストアドプロパティの初期化
    @State private var isAutoStopEnabled: Bool
    
    // ハプティックフィードバック種別の初期化
    @State private var selectedHapticTypeIndex: Int
    
    init(store: StoreOf<SettingsReducer>) {
        self.store = store
        
        // initメソッドの中で静的メソッドとして実装し、selfを使わないようにする
        func getIndexFromHapticType(typeRaw: String?) -> Int {
            guard let typeString = typeRaw,
                  let type = HapticType(rawValue: typeString),
                  let index = HapticType.allCases.firstIndex(of: type) else {
                // デフォルトは0（default）
                return 0
            }
            return index
        }
        
        let userDefaultsManager = UserDefaultsManager.shared
        
        // ストアドプロパティの初期化
        _isAutoStopEnabled = State(initialValue: userDefaultsManager.object(forKey: .stopVibrationAutomatically) as? Bool ?? true)
        
        // ハプティックフィードバック種別の初期化 - ローカル関数を使用
        let typeRaw = userDefaultsManager.object(forKey: .hapticType) as? String
        _selectedHapticTypeIndex = State(initialValue: getIndexFromHapticType(typeRaw: typeRaw))
    }
    
    // クラスメソッドとして残しておく場合は、静的メソッドにする
    private static func getIndexFromHapticType(typeRaw: String?) -> Int {
        guard let typeString = typeRaw,
              let type = HapticType(rawValue: typeString),
              let index = HapticType.allCases.firstIndex(of: type) else {
            // デフォルトは0（default）
            return 0
        }
        return index
    }
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            List {
                Section {
                    Toggle("Auto-stop after 3s", isOn: viewStore.binding(
                        get: \.stopVibrationAutomatically,
                        send: SettingsAction.toggleStopVibrationAutomatically
                    ))
                }
                
                Section(header: Text("タイマー完了時の振動")) {
                    ForEach(HapticType.allCases) { hapticType in
                        Button(action: {
                            viewStore.send(.selectHapticType(hapticType))
                        }) {
                            HStack {
                                Text(hapticType.rawValue.capitalized)
                                Spacer()
                                if hapticType == viewStore.selectedHapticType {
                                    Image(systemName: "circle.fill")
                                        .foregroundStyle(Color.green.opacity(0.7))
                                        .transition(.opacity)
                                        .animation(.spring(), value: viewStore.selectedHapticType)
                                }
                            }
                        }
                    }
                }
                
                // デバッグセクション
                Section(header: Text("Debug")) {
                    Button("Show Debug Info") {
                        showDebug.toggle()
                    }
                    
                    if showDebug {
                        Button("Reset All Settings") {
                            // TCAの外部でUserDefaultsManagerを直接使用する例
                            UserDefaultsManager.shared.removeAll()
                            // loadSettingsメソッドの代わりに.loadSettingsアクションを送信
                            viewStore.send(.loadSettings)
                        }
                        .foregroundStyle(.red)
                        
                        Button("Print Current Settings") {
                            // 現在の設定を取得して表示
                            let manager = UserDefaultsManager.shared
                            
                            // nilのハンドリング付き
                            let stopAuto = manager.object(forKey: UserDefaultsManager.Key.stopVibrationAutomatically) as? Bool ?? true
                            let hapticTypeRaw = manager.object(forKey: UserDefaultsManager.Key.hapticType) as? String
                            
                            print("Settings: stopAuto=\(stopAuto), hapticType=\(hapticTypeRaw ?? "none")")
                        }
                        .foregroundStyle(.blue)
                    }
                }
            }
            .navigationTitle("設定")
            .onAppear {
                if !viewStore.hasLoaded {
                    // loadSettingsメソッドの代わりに.loadSettingsアクションを送信
                    viewStore.send(.loadSettings)
                }
            }
        }
    }
}