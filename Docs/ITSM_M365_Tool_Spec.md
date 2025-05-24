# ITSM/ISO27001/27002準拠 Microsoft製品運用自動化ツール 仕様書 (v2.2)

## 1. 目的と背景
Microsoft 365, Entra ID, Exchange Online の管理業務自動化ツールに関する仕様書です。
ITSM実践とISO27001/27002の統制要件を満たすことを目的とします。

## 2. 準拠基準
- ISO/IEC 20000
- ISO/IEC 27001
- ISO/IEC 27002

## 3. 構成概要
- Core (認証/ログ/エラー処理)
- Modules (各機能カテゴリ)
- Scheduler (自動実行)
- Reports (CSV/HTML出力)

## 4. システム要件
- OS: Windows 10/11, Server 2019/2022
- 開発言語: PowerShell v7.2+, HTML, JavaScript, CSS
- 認証方式: 非対話型 (証明書認証 or シークレット)
- モジュール: Microsoft.Graph, ExchangeOnlineManagement, MicrosoftTeams
- 実行方式: タスクスケジューラ or CI/CD
- 運用ツールメニュー: CLIメニュー構成

## 5. 実装機能マトリクス
| 機能カテゴリ | 実装モジュール | 対応API |
|--------------|----------------|---------|
| ユーザー管理 | UserManagement.ps1 | Microsoft Graph API |
| グループ管理 | GroupManagement.ps1 | Microsoft Graph API |
| Exchange管理 | ExchangeManagement.ps1 | Exchange Online PowerShell |
| Teams管理 | TeamsManagement.ps1 | Microsoft Teams PowerShell |
| OneDrive管理 | OneDriveManagement.ps1 | SharePoint Online PowerShell |
| ライセンス管理 | LicenseManagement.ps1 | Microsoft Graph API |

## 6. レポート・通知機能
- **レポート種類**:
  - 日次: ユーザー作成/削除、ライセンス変更
  - 週次: グループメンバーシップ変更
  - 月次: コンプライアンス状況
  - 年次: 包括的な監査レポート
- **通知方法**:
  - メール通知 (SMTP)
  - Webhook通知 (ITSMシステム連携)
  - Syslog転送 (SIEM連携)

## 7. 外部連携
- ITSMシステム (REST API)
- SIEM製品 (SyslogまたはHTTPS転送)
- BIツール/DWH (CSV定期出力またはAPI連携)

## 8. ログ管理と保存
- 実行ログ (90日)
- エラーログ (180日)
- 監査ログ (1年)
- 出力形式: テキスト/CSV/HTML

## 9. 導入・運用ガイドライン
- **導入前準備**:
  - 環境調査と要件定義
  - 必要なPowerShellモジュールのインストール
  - 認証情報の準備
- **導入手順**:
  - 設定ファイル(config.json)の作成
  - スクリプトの配置
  - テスト実行
- **運用ガイドライン**:
  - 定期メンテナンススケジュール
  - バックアップ戦略
  - 障害対応フロー

## 10. フォルダ構造
```
MicrosoftAutoMationManagementTools/
├── 📂 Core/                         # 認証・設定・ログ・エラー処理
├── 📂 Modules/                      # 各業務機能モジュール
├── 📂 Reports/                      # レポート出力（自動生成）
├── 📂 Scheduler/                    # スケジュール・自動実行
├── 📂 Logs/                         # ログ管理（ISO準拠）
├── 📂 Templates/                    # HTML・CSVテンプレート
├── 📂 Config/                       # 設定ファイル
├── 📂 Docs/                         # 各種仕様書・手順書
├── 📂 Integrations/                 # 外部連携モジュール
├── 📂 Tools/                        # メンテナンス用スクリプト
├── MainCliMenu.ps1                  # CLIメニュー
└── README.md                        # 全体概要