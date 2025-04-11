# SilentCue - Apple Watch用のサイレントタイマーアプリ

## プロジェクト概要

SilentCueは、Apple Watch専用のタイマーアプリです。Apple Watch特有の触覚フィードバックで通知するため、音を出さずにタイマーを使用できます。

従来のiPhoneタイマーアプリと異なり、腕に装着しているApple Watchだけで完結するため、デバイスを取り出す手間がありません。また、デフォルトでは振動が3秒後に自動停止するため、タイマーが終了した際は、アプリを開いて操作する必要がなく、より快適なユーザー体験を提供します。

振動の強さや停止機能のオン・オフなど、各種設定は好みに合わせてカスタマイズできます。

## アーキテクチャ

このプロジェクトはThe Composable Architecture (TCA 1.19.0)のシンプル版を使用し、独立した機能に焦点を当てています：

- **機能ごとの状態管理**: 各機能（タイマー、設定）が独自の状態とロジックを維持
- **直接的なナビゲーション**: SwiftUIのNavigationStackとコールバックを使用
- **最小限の状態管理**: グローバル状態コンテナなし、機能ごとのストアのみ

## ディレクトリ構成

```
SilentCue/
├── SilentCue Watch App/
│   ├── Domain/
│   │   ├── Timer/
│   │   └── Settings/
│   ├── View/
│   │   ├── TimerStartView.swift
│   │   ├── CountdownView.swift
│   │   └── SettingsView.swift
│   ├── Model/
│   ├── StorageService/
│   └── Util/
├── .swiftformat
├── .swiftlint.yml
├── Mintfile
└── .github/workflows/
```

## 技術スタック

- **言語とフレームワーク**
  - Swift
  - SwiftUI
  - WatchKit

- **状態管理**
  - The Composable Architecture 1.19.0

- **永続化**
  - UserDefaults

- **ネイティブ機能**
  - WKExtendedRuntimeSession
  - WKHapticType

- **開発ツール**
  - SwiftFormat
  - SwiftLint
  - Mint
  - GitHub Actions（CI/CD）

## 主要機能

### 直感的なタイマー設定
Apple Watchの小さな画面でも使いやすさを重視した洗練されたインターフェースを提供します。時間を直感的に設定でき、分数を指定する他に特定の時刻までの正確なカウントダウンにも対応しています。

### 振動による無音通知
Apple Watch独自の触覚フィードバック機能を活用し、最小限の音でタイマーの完了を通知します。複数の振動パターンから好みの振動を選択することも可能です。

### 自動停止機能
タイマー完了時の振動が3秒後に自動的に停止するため、アプリを開いて操作する必要がありません。これにより、スムーズな体験を実現します。

### カスタマイズ可能な設定
触覚フィードバックのパターンや強度、自動停止機能のオン・オフなど、様々な設定をユーザーの好みに合わせて調整できます。各設定は永続的に保存され、アプリを再起動しても維持されます。

### バックグラウンド実行
Apple Watchアプリを閉じた後もタイマーが正確に動作し続けます。WKExtendedRuntimeSessionを活用した高度なバックグラウンド処理により、アプリがバックグラウンドにある状態でも正確な時間計測と通知を実現しています。長時間のタイマーでも精度を維持します。

## 環境構築

### Mint

Mintを使用してSwiftFormatとSwiftLintを管理しています。以下のコマンドで初期設定が可能です：

```bash
brew install mint
mint bootstrap
```

TCAなどの依存パッケージはSwift Package Managerによって自動的に管理されるため、Xcodeがプロジェクトを開く際に必要なパッケージを自動的にダウンロードします。

## テスト

### テスト環境

SilentCueは以下のテスト環境を活用しています：

- **XCTest**: Appleの標準テストフレームワーク
- **TestStore**: TCAが提供するテスト用ストア
- **TestClock**: TCAの時間依存テスト用ユーティリティ
- **GitHub Actions**: CI環境での自動テスト
- **WatchOS Simulator**: シミュレータ環境でのテスト実行

### テストの種類と対象

- **ユニットテスト**: 個々の機能単位のテスト
  - **Reducerテスト**: アクションによる状態変化検証（TimerReducer, SettingsReducer）
  - **モデルテスト**: ビジネスロジックの検証（TimerState, HapticType）
  - **ユーティリティテスト**: 永続化機能の検証（UserDefaultsManager）

- **統合テスト**: 複数モジュール間の連携検証
  - **フィーチャー連携テスト**: タイマーと設定機能間の連携

### WatchKit依存性の課題

- **CI環境での制約**: 
  - ハプティックフィードバック（WKHapticType）など、実機でしか完全に検証できない機能
  - シミュレータでの制限（一部APIはシミュレータでは機能しない）
  - CIパイプラインでの実機テスト不可

- **テストの葛藤**: 
  - 全ての機能を網羅的にテストしたい
  - ハードウェア依存の部分はCIやシミュレータで検証困難
  - アクション発行順序の厳密なテストと実行環境の制約の両立

### モック実装とテスト分離

実際のコードでは以下の分離戦略を採用しています：

```swift
// 依存性の抽象化（インターフェース）
protocol UserDefaultsManaging {
    func set<T>(_ value: T?, forKey key: UserDefaultsKey)
    func get<T>(forKey key: UserDefaultsKey) -> T?
}

// テスト用モック実装
class MockUserDefaultsManager: UserDefaultsManaging {
    var mockReturnValues: [UserDefaultsKey: Any] = [:]
    
    func set<T>(_ value: T?, forKey key: UserDefaultsKey) {
        mockReturnValues[key] = value
    }
    
    func get<T>(forKey key: UserDefaultsKey) -> T? {
        return mockReturnValues[key] as? T
    }
}

// テストコード例
func testSaveSettings() async {
    let userDefaultsManager = MockUserDefaultsManager()
    let store = TestStore(
        initialState: SettingsState(),
        reducer: {
            SettingsReducer()
                .dependency(\.userDefaultsManager, userDefaultsManager)
        }
    )
    // テストロジック...
}
```

### 採用したアプローチ

- **テストストアの厳密性調整**: TCAのTestStoreで`exhaustivity = .off`を選択的に使用
  - **メリット**: CI環境でもビルドと基本的な機能検証が可能になる
  - **デメリット**: 一部アクションや状態変化の厳密な検証を犠牲にする
  - **実装例**:
  ```swift
  // 厳密性を一時的に無効化して特定のテストだけを行う
  func testPreviewHapticFeedback() async {
      let store = TestStore(...)
      
      // テスト全体で厳密性を無効化
      store.exhaustivity = .off
      
      // プレビュー開始テスト
      await store.send(.previewHapticFeedback(.weak))
      
      // プレビュー完了テスト
      await store.send(.previewHapticCompleted)
  }
  ```

- **選択的なテストスキップ**: 
  - ハードウェア依存の部分は実機テストに委ね、CI環境ではコア機能に集中
  - 厳密性調整と環境検出を組み合わせたアプローチ
  - CI環境向けの特殊なテストプランの活用

- **時間依存テストの処理**:
  - `TestClock<Duration>`を使った時間操作によるタイマー機能テスト
  ```swift
  func testTimerCompletion() async {
      let clock = TestClock<Duration>()
      let store = testReducer(clock: { clock })
      
      // タイマー開始
      await store.send(.startTimer) { ... }
      
      // 時間を進めるシミュレーション
      await clock.advance(by: .seconds(180))
      
      // タイマー完了の検証
      await store.receive(.timerCompleted) { ... }
  }
  ```

### CI環境での自動テスト

GitHub Actionsを使用してCIパイプラインを構築しています：

```yaml
# .github/workflows/silent_cue_ci.yml
test:
  name: Run Tests
  runs-on: macos-latest
  steps:
  - name: Run Unit Tests
    run: |
      xcodebuild test \
        -project SilentCue.xcodeproj \
        -scheme "SilentCue Watch AppTests" \
        -destination "platform=watchOS Simulator,name=Apple Watch Series 10 (42mm)" \
        -testPlan "SilentCue Watch AppTests" \
        CODE_SIGNING_REQUIRED=NO
```

### 今後の改善方針

- **関心の分離強化**: 
  - ハードウェア依存コードとビジネスロジックの明確な分離
  - 機能インターフェース定義とプラットフォーム実装の分離

- **依存性注入の改善**: 
  - テスト容易性を高めるインターフェース設計
  - TCAの依存性注入機能の積極活用
  - 複雑な依存関係のモック化簡略化

- **環境検出機能**: 
  - テスト環境を自動検出し、適切な実装を選択する仕組み
  - フラグによるテスト時の振る舞い変更
  ```swift
  #if DEBUG
  // テスト環境用の実装
  #else
  // 実機環境用の実装
  #endif
  ```

- **テスト戦略の細分化**:
  - 単体テスト: ロジックの分離検証
  - 統合テスト: 機能間の連携検証
  - UI/UXテスト: ユーザー体験の検証
  - パフォーマンステスト: タイマー精度・バッテリー消費の検証

この方針により、CI環境での継続的なテストと、実機での機能確認を両立しています。テスト可能性を高めつつ、実装の柔軟性と拡張性も維持する設計を目指しています。
