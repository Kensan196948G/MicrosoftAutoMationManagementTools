# レポート生成仕様書

## 1. レポート保存構造
- 年次レポート: `Reports/Annual/ComplianceSummary_YYYY.md`  
  例: `ComplianceSummary_2024.md`
- 月次レポート: `Reports/Monthly/UsageReport_YYYYMM.md`  
  例: `UsageReport_202405.md`
- アドホック（日次）レポート: `Reports/AdHoc/`配下に日付ごとに生成  
  例: `AdHoc/UsageReport_20250524.md`

## 2. レポート生成トリガー
- スケジュール起動  
  - 既存の`Scheduler/TaskScheduler.ps1`と連携し、定期的にレポート生成を実行  
  - 年次・月次はそれぞれ年初・月初に自動生成  
- 手動起動  
  - 管理者が必要に応じて手動でレポート生成をトリガー可能

## 3. データソース
- Microsoft非対話型認証を用いたGraph API連携  
- Active Directory接続によるユーザ・グループ情報取得  
- いずれも安全な認証情報管理と接続監査を実施

## 4. 出力フォーマット
- Markdown（.md）  
- HTML（.html）  
- CSV（.csv）  
- フォーマットは用途に応じて選択可能

## 5. セキュリティ要件
- ISO27001 Annex A.12.4（ログ管理）に準拠  
- レポート生成時の認証情報は暗号化管理  
- アクセス制御を実装し、権限のないユーザによる閲覧・操作を防止  
- ログは`Logs/ErrorFix/`および`Logs/History/`に保存し、監査可能とする

## 6. 既存システム連携
- `Scheduler/TaskScheduler.ps1`のジョブ定義にレポート生成タスクを追加可能  
- スクリプトの拡張性を考慮し、将来的なレポート種別追加に対応可能な設計とする

---

以上