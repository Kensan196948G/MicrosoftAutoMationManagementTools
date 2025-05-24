# 検証システムアーキテクチャ

## 主要コンポーネント
- `Invoke-FullValidation.ps1`: 統合検証スクリプト
- `validate_environment.ps1`: 環境検証モジュール
- `Core/Logging.ps1`: ロギング統合モジュール

## 実行シナリオ
```powershell
# 基本実行例
.\Tools\Invoke-FullValidation.ps1 -Scope All

# CI/CD統合例
- task: PowerShell@2
  inputs:
    filePath: 'Tools/Invoke-FullValidation.ps1'
    arguments: '-Scope Security -ReportFormat JSON'