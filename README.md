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
