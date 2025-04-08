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
    
    // アラート表示用の状態変数
    @State private var showResetAlert = false
    @State private var showResetConfirmationAlert = false
    
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
                    Toggle("auto-stop after 3s", isOn: viewStore.binding(
                        get: \.stopVibrationAutomatically,
                        send: SettingsAction.toggleStopVibrationAutomatically
                    ))
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
                                        .foregroundStyle(Color.green.opacity(0.7))
                                        .transition(.opacity)
                                        .animation(.spring(), value: viewStore.selectedHapticType)
                                }
                            }
                        }
                    }
                }
                
                // Danger Zone
                Section(header: Text("Danger Zone")) {
                    Button("Reset All Settings") {
                        showResetConfirmationAlert = true
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("設定")
            .onAppear {
                if !viewStore.hasLoaded {
                    viewStore.send(.loadSettings)
                }
            }
            .alert("すべての設定項目が初期値に戻されました", isPresented: $showResetAlert) {
                Button("OK") {
                    showResetAlert = false
                }
            }
            .alert("設定をリセットしますか？", isPresented: $showResetConfirmationAlert) {
                Button("キャンセル", role: .cancel) {
                    showResetConfirmationAlert = false
                }
                Button("リセット", role: .destructive) {
                    UserDefaultsManager.shared.removeAll()
                    viewStore.send(.loadSettings)
                    showResetConfirmationAlert = false
                    
                    // 少し遅延させて完了アラートを表示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showResetAlert = true
                    }
                }
            } message: {
                Text("この操作は取り消せません")
            }
        }
    }
}
