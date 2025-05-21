 🛡️ ITSM/ISO27001/27002準拠 Microsoft製品運用自動化ツール 仕様書（Ver. 1.0）
---

 🎯 1. 目的と背景

 🎯 1.1 目的
Microsoft 365・Entra ID（旧Azure AD）・Exchange Onlineの管理業務を対象としたPowerShellベースの自動化ツールにより、ITSM実践とISO27001/27002の統制要件を同時に満たす。

 🧩 1.2 準拠基準
- ✅ ISO/IEC 20000
- ✅ ISO/IEC 27001
- ✅ ISO/IEC 27002

---

 👥 2. 適用対象
- 👨‍💼 IT管理者／システム運用担当者
- 🔐 セキュリティ管理者
- 🧾 内部統制／監査担当者

---

 🧱 3. 構成概要
```text
M365自動化ツール
├─ Core（認証／ログ／エラー処理）
├─ Modules（各機能カテゴリ）
├─ Scheduler（自動実行）
└─ Reports（CSV／HTML出力）
```

---

 ⚙️ 4. システム要件

| 💻 項目      | 🔧 要件                                                 |
|-------------|----------------------------------------------------------|
| OS 　　　　　| Windows 10/11, Server 2019/2022 　　　　　　　　　　　　　　　 |
| 開発言語、技術|PowerShell v7.2+（推奨）、HTML+JavasScript＋CSS 　　　　　　　　| 
| 認証方式　　 | 非対話型（証明書認証 or シークレット） |
| モジュール 　　| Microsoft.Graph, ExchangeOnlineManagement, MicrosoftTeams |
| 実行方式    | タスクスケジューラ or CI/CD 　　　　　　　　　　　　　　　            |
| 運用ツールメニュー| CLIメニュー構成　　　　　　　　　　　　　　　　　　　　　　　　　　　 |

---

 🧩 5. 実装機能マトリクス

 👤 ユーザー管理
- UM-001: 👥 アカウント一括作成
- UM-002: 📴 有効/無効化切替
- UM-003: 🔐 MFA未設定者抽出
- UM-004: 🕒 無操作ユーザー検出
- UM-005: 📝 AD属性一括更新

 🏷️ グループ管理
- GM-001: 📁 動的グループ作成
- GM-002: ➕➖ メンバー一括管理
- GM-003: 📊 棚卸レポート出力

 📬 Exchange Online
- EX-001: 📦 容量監視
- EX-002: 📎 添付追跡
- EX-003: ✉️ 自動応答設定
- EX-004: 🗃️ アーカイブ有効化
- EX-005: 👥 配布グループ管理
- EX-006: 📅 会議室監査
- EX-007: 🚫 スパム分析
- EX-008: 🛑 送信制限設定

 📂 OneDrive / 📞 Teams / 🪪 ライセンス
- OD-001: 🧮 容量監視
- OD-002: 📈 ユーザー利用分析
- TM-001: 📋 チーム一覧取得
- TM-002: 🚫 録画禁止ポリシー
- LM-001: 🎫 ライセンス自動付与
- LM-002: 📊 利用状況分析

---

 📊 6. レポート・通知機能

 🗓️ 日次レポート

| 📄 名称 | 📌 内容 | 📤 通知 | 🎯 対象部門 |
|--------|-------|--------|-------------|
| MFA未設定リスト | MFA未対応ユーザー抽出 | メール／Teams通知 | セキュリティ |
| 異常サインイン | 海外アクセス・深夜アクセス | 警告メール | 監査／SOC |
| アカウント操作ログ | 作成／削除／無効化記録 | ログファイル保存 | IT運用 |

 📅 週次レポート

| 📄 名称 | 📌 内容 | 📤 通知 | 🎯 対象部門 |
|--------|--------|--------|-------------|
| グループ棚卸 | 所属メンバー変動の可視化 | メール通知 | 情報統制 |
| メール容量監視 | 80%超過時に通知 | メール通知 | ヘルプデスク |
| OneDrive利用率 | 利用者別統計分析 | チーム通知 | IT部門 |

 📆 月次レポート

| 📄 名称 | 📌 内容 | 📤 通知 | 🎯 対象部門 |
|--------|--------|--------|-------------|
| ライセンス利用状況 | 割当と使用率の乖離分析 | メール通知 | 経理／情シス |
| スパムメール統計 | スパム傾向／件数の統計 | メール通知 | セキュリティ |
| 脆弱アカウント分析 | 外部転送や弱パスワード等 | 管理者通知 | 情報統制 |

 📈 年次レポート

| 📄 名称 | 📌 内容 | 📤 通知 | 🎯 対象部門 |
|--------|--------|--------|-------------|
| コンプライアンス評価 | ISMS要件満足度と改善要件 | 管理者配信 | 経営層／監査 |
| 統合操作統計 | API実行回数、失敗率など | 会議用 | 情報セキュリティ |
| 全ユーザー一覧 | アカウント／ライセンス全体像 | 保存用 | IT監査／法務 |

---

 🌐 7. 外部連携
- 📮 ITSMシステム：チケット自動発行（REST API）
- 🔒 SIEM製品：SyslogまたはHTTPS転送
- 📊 BIツール／DWH：CSV定期出力またはAPI連携

---

 🗃️ 8. ログ管理と保存
- ✅ 実行ログ（90日）
- ✅ エラーログ（180日）
- ✅ 監査ログ（1年）
- 📁 出力形式：テキスト／CSV／HTML

---

 📌 9. 導入・運用ガイドライン
1. PowerShell／Graph SDKインストール
2. Entra IDでのアプリ登録とAPI権限構成
3. 証明書またはクライアントシークレット設定
4. config.json暗号化保存
5. スケジューラと通知設定

---

📁 10.M365Tools（ルートフォルダ）
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
│   └── secrets.enc.json            # ※暗号化された認証情報ファイル
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
└── README.md                      # 全体概要と導入手順リンク
