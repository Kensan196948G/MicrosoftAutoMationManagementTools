# Microsoft製品運用自動化ツール (v2.2)

## 概要
- **セキュリティ強化**:
  - WinRM接続にSSL/TLS 1.2以上を必須化
  - Kerberos認証を標準採用
  - 詳細は[セキュリティポリシー](Docs/SecurityPolicy.md)参照

本ツールは、Microsoft 365, Entra ID (旧 Azure AD), Exchange Online の管理業務を自動化し、ITSMプラクティスとISO27001/27002の統制要件に準拠することを目的としています。PowerShellベースで開発されており、各種管理タスクの効率化とセキュリティ強化に貢献します。

## 主要機能 (v2.2更新)
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
│   ├── secrets.enc.json            # 暗号化された認証情報 (AES-256)
│   └── secrets.enc.template.json   # テンプレートファイル
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
5. `Config/secrets.enc.json`の設定 (AES-256暗号化推奨)
6. 環境に合わせたタスクスケジューラの設定
 
詳細な導入手順は `Docs/Operation_Guide.md` を参照してください。

## 貢献
本プロジェクトへの貢献を歓迎します。詳細については、CONTRIBUTING.md を参照してください。
(現在、CONTRIBUTING.md は存在しません)

## ライセンス
このプロジェクトは、MITライセンスの下で公開されています。

## 関連ドキュメント

- [Active Directory接続セキュリティ設計書](Docs/AD_Connection_Security_Design.md)
- [Active Directory PowerShellリモート管理手順書](Docs/Active%20Directory%20PowerShell%E3%83%AA%E3%83%A2%E3%83%BC%E3%83%88%E7%AE%A1%E7%90%86%E3%83%BB%E6%93%8D%E4%BD%9C%20%E8%A9%B3%E7%B4%B0%E6%89%8B%E9%A0%86%E6%9B%B8.txt)
- [ITSM/M365ツール仕様書](Docs/ITSM_M365_Tool_Spec.md)
- [運用ガイド](Docs/Operation_Guide.md)
- [セキュリティポリシー](Docs/SecurityPolicy.md)

