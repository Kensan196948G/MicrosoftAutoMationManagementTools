# Microsoft製品運用自動化ツール

## 概要
本ツールは、Microsoft 365, Entra ID (旧 Azure AD), Exchange Online の管理業務を自動化し、ITSMプラクティスとISO27001/27002の統制要件に準拠することを目的としています。PowerShellベースで開発されており、各種管理タスクの効率化とセキュリティ強化に貢献します。

## 主要機能
- **CLIメニュー:** PowerShellプロンプト上で対話的に操作できるCLIメニューを提供し、各機能へのアクセスを容易にします。
- **Coreモジュール:** 認証、ログ管理、エラー処理などの基盤機能を提供します。
- **機能モジュール:** ユーザー管理、グループ管理、Exchange Online管理、OneDrive/Teams管理、ライセンス管理など、多岐にわたる自動化機能を提供します。
- **レポート・通知機能:** 定期的なレポート作成と異常検知時の通知機能を備え、運用状況の可視化と迅速な対応を支援します。
- **スケジュール機能:** タスクスケジューラやCI/CDツールとの連携により、自動実行を可能にします。
- **外部連携:** ITSMシステム、SIEM製品、BIツールなどとの連携を想定しています。

## フォルダ構造
```
MicrosoftAutoMationManagementTools/
├── 📂 Core/                         # 認証・設定・ログ・エラー処理
│   ├── Authentication.ps1
│   ├── Configuration.ps1
│   ├── Logging.ps1
│   └── ErrorHandling.ps1
│
├── 📂 Modules/                      # 各業務機能モジュール
│   ├── UserManagement.ps1
│   ├── GroupManagement.ps1
│   ├── ExchangeManagement.ps1
│   ├── OneDriveManagement.ps1
│   ├── TeamsManagement.ps1
│   └── LicenseManagement.ps1
│
├── 📂 Reports/                      # レポート出力（自動生成）
│   ├── 📂 Daily/
│   ├── 📂 Weekly/
│   ├── 📂 Monthly/
│   └── 📂 Annual/
│       └── 📄 ComplianceSummary_YYYY.md
│
├── 📂 Scheduler/                    # スケジュール・自動実行
│   ├── TaskScheduler.ps1
│   └── JobDefinitions/
│       ├── Run-DailyTasks.ps1
│       └── Run-MonthlyTasks.ps1
│
├── 📂 Logs/                         # ログ管理（ISO準拠）
│   ├── RunLogs/
│   ├── ErrorLogs/
│   └── AuditLogs/
│
├── 📂 Templates/                   # HTML・CSVテンプレート
│   ├── HTMLReportTemplate.html
│   ├── MFA_Template.csv
│   └── GroupMember_Template.csv
│
├── 📂 Config/                      # 設定ファイル
│   ├── config.json
│   └── secrets.enc.json            # ※現在利用していません。ClientSecretは実行時に入力します。
│
├── 📂 Docs/                        # 各種仕様書・手順書
│   ├── ITSM_M365_Tool_Spec.md
│   ├── Installation_Guide.pdf
│   ├── Operation_Guide.md
│   └── SecurityPolicy.md
│
├── 📂 Integrations/               # 外部連携モジュール（ITSM / SIEM）
│   ├── DeskNetsNeo_API.ps1
│   ├── SIEM_SyslogSender.ps1
│   └── WebhookNotifier.ps1
│
├── 📂 Tools/                      # メンテナンス用・補助スクリプト
│   ├── CleanupObsoleteUsers.ps1
│   ├── LicenseOptimizer.ps1
│   └── BackupConfigs.ps1
│
├── MainCliMenu.ps1                # PowerShellプロンプト用CLIメニュー
└── README.md                      # 全体概要と導入手順リンク
 
## 導入手順
1. PowerShell v7.2+のインストール
2. 必要なPowerShellモジュールのインストール (Microsoft.Graph, ExchangeOnlineManagement, MicrosoftTeams)
3. Entra IDでのアプリケーション登録とAPI権限構成
4. `Config/config.json`の設定
5. ツール実行時、Client Secretはプロンプトで入力してください。(secrets.enc.jsonは現在使用していません。)
6. 環境に合わせたタスクスケジューラの設定
 
詳細な導入手順は `Docs/Installation_Guide.pdf` または `Docs/Operation_Guide.md` を参照してください。

## 貢献
本プロジェクトへの貢献を歓迎します。詳細については、CONTRIBUTING.md を参照してください。
(現在、CONTRIBUTING.md は存在しません)

## ライセンス
このプロジェクトは、MITライセンスの下で公開されています。

## Active Directory PowerShellリモート管理について

本ツールのActive Directory PowerShellリモート管理機能を利用する際は、以下の点にご注意ください。

- ADWS (Active Directory Web Services) を起動する際は、必ず管理者権限でPowerShellを実行してください。権限不足により接続エラーが発生する場合があります。
- RSAT (Remote Server Administration Tools) の導入はWindowsのバージョンに依存します。Windows 10/11のバージョンに応じたRSATのインストールを行ってください。
- よくあるエラー例と対処法については、Docs/Active Directory PowerShellリモート管理・操作 詳細手順書.txtを参照してください。
- リモートコマンドの実行例は表記を統一しており、`Invoke-Command -ComputerName <サーバー名> -ScriptBlock { <コマンド> }` の形式を推奨しています。
