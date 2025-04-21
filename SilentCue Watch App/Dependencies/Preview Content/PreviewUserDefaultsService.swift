#if DEBUG

    import Foundation

    /// プレビューおよびUIテストで使用するための軽量なUserDefaultsService実装
    final class PreviewUserDefaultsService: UserDefaultsServiceProtocol {
        // データを保持するためのインメモリ辞書
        private var storage: [String: Any] = [:]

        /// 指定されたキーに値を設定します（プレビュー/テスト用）。
        func set(_ value: Any?, forKey defaultName: UserDefaultsKeys) {
            print("💾 [プレビューUserDefaults] セット \(defaultName.rawValue): \(String(describing: value))")
            if let value {
                storage[defaultName.rawValue] = value
            } else {
                storage.removeValue(forKey: defaultName.rawValue)
            }
        }

        /// 指定されたキーに関連付けられたオブジェクトを返します（プレビュー/テスト用）。
        func object(forKey defaultName: UserDefaultsKeys) -> Any? {
            let value = storage[defaultName.rawValue]
            print("💾 [プレビューUserDefaults] ゲット \(defaultName.rawValue): \(String(describing: value))")
            return value
        }

        /// 指定されたキーの値を削除します（プレビュー/テスト用）。
        func remove(forKey defaultName: UserDefaultsKeys) {
            print("💾 [プレビューUserDefaults] 削除 \(defaultName.rawValue)")
            storage.removeValue(forKey: defaultName.rawValue)
        }

        /// すべての値を削除します（プレビュー/テスト用）。
        func removeAll() {
            print("💾 [プレビューUserDefaults] 全削除")
            storage.removeAll()
        }

        // --- Preview/Test Specific Methods (Optional) ---

        /// 特定の初期値を設定するために使用 (UIテストで便利)
        func setupInitialValues(_ values: [UserDefaultsKeys: Any]) {
            print("💾 [プレビューUserDefaults] 初期値設定: \(values.mapValues { String(describing: $0) })")
            removeAll()
            for (key, value) in values {
                set(value, forKey: key)
            }
        }
    }

#endif
