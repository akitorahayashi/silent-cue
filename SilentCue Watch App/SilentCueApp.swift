import SwiftUI
import ComposableArchitecture

@main
struct SilentCue_Watch_AppApp: App {
    // TCA 1.19.0に対応するStoreの初期化
    let store: StoreOf<RootFeature> = Store(initialState: RootFeature.State()) {
        RootFeature()
    }
    
    // アプリのカラースキームを管理する状態変数
    @State private var colorScheme: ColorScheme = .dark
    
    var body: some Scene {
        WindowGroup {
            RootView(store: store)
                .preferredColorScheme(colorScheme)
                .onAppear {
                    // UserDefaultsからテーマ設定を読み込む
                    let isLightMode = UserDefaultsManager.shared.object(forKey: .appTheme) as? Bool ?? false
                    colorScheme = isLightMode ? .light : .dark
                }
                .onChange(of: UserDefaultsManager.shared.object(forKey: .appTheme) as? Bool) { isLightMode in
                    // 設定変更を監視して反映
                    colorScheme = (isLightMode ?? false) ? .light : .dark
                }
        }
    }
}
