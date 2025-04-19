# Unit Testing Guidelines (Composable Architecture)

This document outlines guidelines and best practices for writing unit tests for features built with the Composable Architecture (TCA) in the SilentCue project.

## 1. TCA テストの基本

### 1.1. `TestStore` のセットアップ

*   **ツール:** Reducer のテストには `TestStore` を使用します。
*   **初期化:** `reducer`, 完全な `initialState`, そして `withDependencies` ブロックで関連する全ての依存関係をオーバーライドして初期化します。
*   **`@MainActor`:** テストクラス (`XCTestCase` サブクラス) に `@MainActor` を付けます。
*   **初期状態:** `TestStore` を初期化する *前* に、完全な初期状態を構築します。テスト中に `store.state` を直接変更することはできません (get-only)。

```swift
@MainActor
final class MyFeatureTests: XCTestCase {
    func testFeatureFlow() async {
        // 1. 依存関係の準備 (Clock, Mocks)
        let clock = TestClock() // 時間ベースのテストには TestClock を使用
        let mockService = MockMyService()

        // 2. 完全な初期状態の構築
        var initialState = MyFeature.State(/* ... */)
        // State が初期日付を必要とする場合、ここで withDependencies を使用:
        await withDependencies {
            $0.continuousClock = clock // TestClock を提供
        } operation: {
            // .date にアクセスすると、提供された TestClock が正しく使用される
            @Dependency(\.date) var date
            initialState.createdAt = date()
        }

        // 3. TestStore の初期化
        let store = TestStore(
            initialState: initialState, // 完全に構築された State を渡す
            reducer: { MyFeature() },
            withDependencies: { dependencies in
                // Reducer/Effect で使用される *全て* の依存関係をオーバーライド (ただし .date を除く)
                dependencies.continuousClock = clock // Clock を設定
                dependencies.myService = mockService
                // 重要: dependencies.date を明示的にオーバーライドしない！
                // TCA は自動的に .date を .continuousClock にリンクします。
                // ... その他の依存関係 ...
            }
        )
        // ... テストロジック ...
    }
}
```

### 1.2. アクションの送信と状態変化のテスト

*   `await store.send(.actionName)` を使用してアクションをシミュレートします。
*   末尾クロージャを提供し、期待される *全ての* 同期的な状態変化をアサートします。

### 1.3. エフェクトからのアクション受信のテスト

*   `await store.receive(.responseAction)` を使用して、エフェクトによって生成されたアクションをアサートします。
*   必要に応じて `timeout` を含めます。
*   受信したアクションが処理されたときの状態変化をアサートするために、末尾クロージャを含めることができます。
*   **順序:** エフェクトによって生成される全ての期待されるアクションを `receive` する前に、後続のアクション（特にエフェクトをキャンセルする可能性のあるもの）を送信しないように注意してください。

### 1.4. 時間ベースのロジックのテスト

*   **`TestClock`:** `TestStore` のセットアップで `continuousClock` を `TestClock` でオーバーライドします。**これが鍵です。**
*   **時間の進行:** `await clock.advance(by: .duration)` を使用します。
*   **`@Dependency(\.date)`:** この依存関係は、`continuousClock` に提供された `TestClock` を **自動的に使用します**。Reducer 内でも、テストコード内の適切に設定された `withDependencies` ブロックを介してアクセスした場合でも同様です。明示的な `DateGenerator` のオーバーライドは不要であり、望ましくありません。
*   **期待される日付の計算:** テストコード内でアサーションのために `TestClock` に従った「現在」時刻を知る必要がある場合は、`await withDependencies { $0.continuousClock = clock } operation: { @Dependency(\.date) var date; /* date() を使用 */ }` を使用します。
*   **タイマーと遅延のテスト (`SettingsReducer` 例):**
    *   `clock.timer(interval:)` を使用したエフェクトは、`clock.advance(by: interval)` で時間を進めると Tick アクション (`.hapticPreviewTick`) を受信できます。
    *   `clock.sleep(for:)` を使用した遅延エフェクトは、指定された時間だけ `clock.advance(by:)` で時間を進めると完了アクション (`.stopHapticPreview`) を受信できます。
    *   テストでは、これらのアクションの受信とそれに伴う状態変化（例: `isPreviewingHaptic`）や副作用（例: `hapticsService.play` 呼び出し）をアサートします。

### 1.5. エフェクトの完了とキャンセル

*   **`await store.finish()`:** 全てのエフェクトが完了し、予期しないアクションが発生しなかったことを確認するために、テストの最後に呼び出します。
*   **キャンセル:** 長時間実行されるエフェクト（タイマーや `AsyncStream` 購読など）が正しくキャンセルされることをテストします。
    *   キャンセルを引き起こすアクション（例: `.stopHapticPreview`, `.backButtonTapped`, `.selectHapticType`)を `send` します。
    *   もしキャンセルアクションが別のリアクション（例: 状態変更）を引き起こす場合、それを `receive` します。
    *   **重要:** `await store.finish()` を呼び出します。これにより、キャンセル対象のエフェクト（例: `hapticPreviewTimer`, `hapticPreviewTimeout`）が実際に終了し、追加の Tick や Timeout アクションを送信しないことが保証されます。
*   **時間の進行:** タイマーエフェクトの期間をカバーするように `clock.advance(by:)` を使用します。

### 1.6. Exhaustivity と Skipping

*   デフォルトの網羅性 (`.on`) を推奨します。
*   `skipReceivedActions()` / `skipInFlightEffects()` は慎重に使用します。アクション送信直後の状態変化と依存関係呼び出しのみを検証したい場合に `skipInFlightEffects()` は有用です (例: `testStartTimer_MinutesMode`)。

## 2. 依存関係の管理

*   **`TestStore` でのオーバーライド:** Reducer が使用する可能性のある *全ての* 依存関係を、`TestStore` のメインの `withDependencies` ブロック内でオーバーライドします（`.date` を除く）。モック実装 (`TestSupport/Mock/`) やテスト固有のインスタンス (`TestClock`) を使用します。
*   **テストスコープでの計算 (`withDependencies`):**
    *   Reducer のロジックではなく、*テストロジック* がテスト設定に基づいた依存関係（最も一般的なのは `TestClock` を使用して期待される日時を計算するための `@Dependency(\.date)`）にアクセスする必要がある場合は、その特定のコードブロックを `await withDependencies { ... }` でラップします。
    *   このブロック内では、計算に必要な *基本* 依存関係（例: `$0.continuousClock = clock`）のみを設定します。
    *   目的の依存関係（例: `@Dependency(\.date) var date`）には、`operation` クロージャ *内* でアクセスします。これは `TestStore` の初期設定（または `continuousClock` のような一時的なオーバーライド）を介して提供されたテストインスタンスを正しく使用します。
    *   **冗長なオーバーライドの回避:** これらのテストスコープの `withDependencies` ブロック内で `$0.date = ...` を明示的に設定しないでください。これは `TestClock` によって制御される日付を取得するという目的を損ないます。

## 3. 高度なテストパターン

### 3.1. `AsyncStream` ベースの依存関係のテスト

依存関係プロトコルが `AsyncStream` プロパティ（例: `var completionEvents: AsyncStream<Void> { get }`）を持つ場合:

1.  **モックの実装:**
    *   モック (`MockExtendedRuntimeService`) 内に `Continuation` を保持します。
    *   プロトコルの `AsyncStream` プロパティを `private(set) lazy var` で実装し、`Continuation` を設定します。
    *   イベントをトリガーするテスト用ヘルパー (`triggerCompletion()`) を追加し、`continuation?.yield()` や `continuation?.finish()` を呼び出します。
    *   `reset()` で `continuation?.finish()` を呼び出し、ストリームをクリーンアップします。
2.  **Reducer のテスト (`TestStore`):**
    *   `TestStore` をセットアップし、モックを注入します。
    *   ストリーム購読を開始するアクション (`send`) を送信します。
    *   モックのヘルパーを呼び出してイベントをシミュレートします。
    *   イベントに応じて Reducer が `send` するアクションを `receive` でアサートします。

### 3.2. デリゲートパターンのテスト (ライブ実装)

`WKExtendedRuntimeSession` のようにモック化が難しいフレームワーク依存オブジェクトを使用し、デリゲートでイベントを処理するサービス (`LiveExtendedRuntimeService`) の場合、**サービス自体のユニットテスト** を作成するのが有効です。

*   **戦略:** サービスがデリゲートメソッドを呼び出されたときに、期待される動作（例: `AsyncStream` へのイベント発行）を行うか検証します。
*   **手順 (`ExtendedRuntimeServiceTests.swift` 例):**
    1.  ライブサービス (`LiveExtendedRuntimeService`) のインスタンスを作成します。
    2.  テストしたいデリゲートメソッド (`extendedRuntimeSessionWillExpire(_:)`) を直接呼び出します（必要ならダミーのフレームワークオブジェクトを渡します）。
    3.  期待される結果（例: `completionEvents` ストリームの変化）をアサートします。

### 3.3. 内部アクションの利用

Reducer 内のステップを調整するために内部アクション（例: `.internal(.finalizeTimerCompletion)`, `.internal(.saveSettingsEffect)`) を使用するのは有効なパターンです。テストではこれらの内部アクションを `await store.receive(...)` でアサートすることで、内部ロジックを検証できます。

### 3.4. 分割されたエフェクト

`startTimer` のように、アクションが複数のエフェクト (`tickerEffect`, `backgroundEffect`) を `Effect.merge` で返す場合、それぞれの `CancelID` (`CancelID.timer`, `CancelID.background`) を使って個別にキャンセルやテストが可能です。同様に `startHapticPreview` では `hapticPreviewTimer` と `hapticPreviewTimeout` のエフェクトが個別に管理されます。

### 3.5. 非同期テストヘルパー

`AsyncStream` の結果を待機するには、`XCTestExpectation` と `Task` を組み合わせたヘルパー関数が便利です (`ExtendedRuntimeServiceTests.swift` 参照)。

## 4. テスト容易性のためのリファクタリング

テストが困難な場合、リファクタリングを検討します。

*   **動機:** テストの複雑さ、脆さ、実行時間の長さ。
*   **手法:**
    *   **外部イベントの `AsyncStream` 化:** Delegate/Callback の代わりに `AsyncStream` を使用。
    *   **エフェクトの分割:** 複雑な副作用を異なる `CancelID` で分割。
    *   **ロジックの共通化:** 内部アクションで類似処理を集約。
    *   **State の単純化:** 計算プロパティを活用。
    *   **複雑な `run` ブロックの分解 (`SettingsReducer` プレビュー例):**
        *   **問題:** 1つのアクション (`previewHapticFeedback`) の `Effect.run` 内で、ループ、`clock.sleep`、複数回の副作用 (`hapticsService.play`) を実行するロジックは、テストが複雑になりがちです。特に、正確な再生回数やタイミングの検証、キャンセル時の動作確認が困難でした。
        *   **解決策:** プレビューロジックを複数のアクションとエフェクトに分割します。
            *   `.startHapticPreview`: 状態 (`isPreviewingHaptic`) を設定し、最初のハプティクスを再生し、2つのキャンセル可能なエフェクトを開始します。
                *   `clock.timer` を使用して定期的に `.hapticPreviewTick` を送信するエフェクト (`CancelID.hapticPreviewTimer`)。
                *   `clock.sleep` を使用して一定時間後に `.stopHapticPreview` を送信するタイムアウトエフェクト (`CancelID.hapticPreviewTimeout`)。
            *   `.hapticPreviewTick`: 受信時に、プレビュー中であればハプティクスを再生するシンプルな副作用を実行します。
            *   `.stopHapticPreview`: 状態をリセットし、タイマーとタイムアウトの両方のエフェクトを `.cancel` で停止します。
        *   **利点:** 各アクションハンドラが単一の責任を持つようになり、テストが容易になります。タイマーや遅延といった時間依存のロジックは TCA が提供する標準的なエフェクトで管理され、`TestClock` を使った検証が容易になります。

## 5. Common Pitfalls & Notes

*   **`try XCTUnwrap`:** `XCTUnwrap` に必要。
*   **`store.state` の不変性:** 初期化後は直接代入不可。
*   **テスト計算用の `withDependencies`:** テスト関数内でテスト依存関係（例: Clock制御の Date）にアクセスするために使用。基本依存関係 (`continuousClock`) を設定し、`.date` のようなリンクされた依存関係はオーバーライドしない。
*   **エフェクトキャンセルタイミング:** キャンセルアクションを `send` する前に、関連する全てのアクションを `receive` する。
*   **State の計算プロパティ:** Reducer とテストを簡潔にする (例: `TimerState.displayTime`)。
*   **廃止予定 API:** リファクタリングで不要になったメソッドは、`unimplemented()` やダミー値を返すようにし、関連テストでその動作を確認 (例: `checkAndClearBackgroundCompletionFlag`)。
*   **アクション名の完全修飾:** `store.send` や `store.receive` でアクションを指定する際、特にリファクタリング後や内部アクション (`.internal(...)`) を使用する場合、コンパイラが型を推論できないことがあります。エラー (`Type 'ActionEnum' has no member...` や `Cannot infer contextual base...`) が発生した場合は、アクション名を省略形 (`.someCase`) ではなく、完全な形 (`FeatureAction.someCase`, `FeatureAction.internal(.someInternalCase)`) で記述してください。

## 6. プロジェクト例

`TimerReducerTests.swift`, `SettingsReducerTests.swift`, `ExtendedRuntimeServiceTests.swift` が実践的な例となります。
