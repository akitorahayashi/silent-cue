#if DEBUG

    import Foundation

    struct PreviewExtendedRuntimeService: ExtendedRuntimeServiceProtocol {
        let completionEvents: AsyncStream<Void> = .finished

        func startSession(duration: TimeInterval, targetEndTime: Date?) {
            print(
                "⏱️ [プレビュー] ExtendedRuntimeService: startSession 呼び出し。期間: \(duration), ターゲット終了時刻: \(String(describing: targetEndTime))"
            )
            // プレビューでは即座に完了ハンドラを呼ぶか、何もしないかを選択できます。
            // completionHandler?()
        }

        func stopSession() {
            print("⏱️ [プレビュー] ExtendedRuntimeService: stopSession 呼び出し。")
        }

        func checkAndClearBackgroundCompletionFlag() -> Bool {
            print("⏱️ [プレビュー] ExtendedRuntimeService: checkAndClearBackgroundCompletionFlag 呼び出し。false を返します。")
            return false // プレビューでは通常 false を返すのが適切
        }
    }

#endif
