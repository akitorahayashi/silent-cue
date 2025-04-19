#if DEBUG

import Foundation

struct PreviewExtendedRuntimeService: ExtendedRuntimeServiceProtocol {
    func startSession(duration: TimeInterval, targetEndTime: Date?, completionHandler: (() -> Void)?) {
        print("वुड [Preview] ExtendedRuntimeService: startSession called. Duration: \(duration), Target End: \(String(describing: targetEndTime))")
        // プレビューでは即座に完了ハンドラを呼ぶか、何もしないかを選択できます。
        // completionHandler?()
    }

    func stopSession() {
        print("वुड [Preview] ExtendedRuntimeService: stopSession called.")
    }

    func checkAndClearBackgroundCompletionFlag() -> Bool {
        print("वुड [Preview] ExtendedRuntimeService: checkAndClearBackgroundCompletionFlag called. Returning false.")
        return false // プレビューでは通常 false を返すのが適切
    }
}

#endif 