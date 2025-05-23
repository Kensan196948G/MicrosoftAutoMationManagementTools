# Microsoft製品運用自動化ツール 運用ガイド

## 1. 概要
本運用ガイドは、Microsoft 365および関連サービスの管理業務を自動化するためのツール運用について説明します。

## 2. 日常運用
### 2.1. スケジュール化されたタスクの監視
タスクスケジューラなどで設定された自動実行ジョブの監視方法について説明します。

### 2.2. ログファイルの確認
定期的にログファイルをチェックし、問題が発生していないか確認します。
- 実行ログ: `Logs/RunLogs/`
- エラーログ: `Logs/ErrorLogs/`
- 監査ログ: `Logs/AuditLogs/`

## 3. エラー発生時の対応
### 3.1. エラーログの分析
エラーが発生した場合、エラーログを確認し、エラーメッセージとスタックトレースから原因を特定します。

### 3.2. 修正手順
一般的なエラーに対する修正手順や、サポートへのエスカレーションパスを定義します。

## 4. レポートの活用
### 4.1. レポートの確認と配布
生成された各種レポート（日次、週次、月次、年次）の確認方法と関係部門への配布手順について説明します。

### 4.2. データ分析と改善
レポートデータを活用して、運用の効率化やセキュリティ強化のための改善策を検討します。

## 5. 定期的なメンテナンス
### 5.1. モジュール更新
各PowerShellモジュールの定期的な更新手順について説明します。

### 5.2. 設定ファイルの管理
`Config/config.json`および`Config/secrets.enc.json`のバックアップ、更新、暗号化解除/再暗号化の手順について説明します。

### 5.3. ログのアーカイブと削除
古いログファイルのアーカイブと削除手順について説明します。

## Active Directory PowerShellリモート管理の注意点 (v2.1)

- **基本要件**:
  - ADWS (Active Directory Web Services) を起動する際は、必ず管理者権限でPowerShellを実行
  - RSAT (Remote Server Administration Tools) の導入はWindowsのバージョンに依存

- **セキュリティ要件**:
  - SSL/TLS 1.2以上が必須 (詳細は[セキュリティ設計書](AD_Connection_Security_Design.md)参照)
  - 基本認証無効化、Kerberos認証推奨
  - 5986ポート(HTTPS)を使用

- **トラブルシューティング**:
  - よくあるエラー例と対処法: `Docs/Active Directory PowerShellリモート管理・操作 詳細手順書.txt` 参照
  - 接続テストコマンド:
    ```powershell
    Test-WSMan -ComputerName <サーバー> -UseSSL -Authentication Kerberos
    ```

- **実行例**:
  ```powershell
  # 推奨形式 (v2.1)
  Invoke-Command -ComputerName <サーバー> -UseSSL -Authentication Kerberos -ScriptBlock { <コマンド> }
  ```

```powershell
Invoke-Command -ComputerName <サーバー名> -ScriptBlock { <コマンド> }
```