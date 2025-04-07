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
    
    // テーマモードの初期化
    @State private var isLightMode: Bool
    
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
        
        // テーマモードの初期化
        _isLightMode = State(initialValue: userDefaultsManager.object(forKey: .appTheme) as? Bool ?? false)
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
                
                Section(header: Text("Appearance")) {
                    // カスタムセグメントコントロール
                    HStack(spacing: 2) {
                        Button {
                            viewStore.send(.toggleThemeMode(true))
                        } label: {
                            Text("Light")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(viewStore.isLightMode ? Color.blue : Color.gray.opacity(0.2))
                                )
                                .foregroundStyle(viewStore.isLightMode ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            viewStore.send(.toggleThemeMode(false))
                        } label: {
                            Text("Dark")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(!viewStore.isLightMode ? Color.blue : Color.gray.opacity(0.2))
                                )
                                .foregroundStyle(!viewStore.isLightMode ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Vibration Type")) {
                    ForEach(HapticType.allCases) { hapticType in
                        Button(action: {
                            viewStore.send(.selectHapticType(hapticType))
                        }) {
                            HStack {
                                Text(hapticType.rawValue.capitalized)
                                Spacer()
                                if hapticType == viewStore.selectedHapticType {
                                    Image(systemName: "circle.fill")
                                        .foregroundStyle(.blue)
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
                            let isLightMode = manager.object(forKey: UserDefaultsManager.Key.appTheme) as? Bool ?? false
                            
                            print("Settings: stopAuto=\(stopAuto), hapticType=\(hapticTypeRaw ?? "none"), lightMode=\(isLightMode)")
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