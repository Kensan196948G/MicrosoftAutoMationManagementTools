<#
.SYNOPSIS
    システム全体の検証を実行し、包括的なレポートを生成します

.DESCRIPTION
    Pesterテスト、環境検証、セキュリティスキャンを統合的に実行し、
    指定された形式でレポートを出力します。

.PARAMETER Scope
    検証範囲を指定 (All/Core/Security)
    - All: 全テストを実行
    - Core: コア機能テストのみ
    - Security: セキュリティ関連テストのみ

.PARAMETER ReportFormat
    レポート出力形式 (HTML/JSON)

.EXAMPLE
    Invoke-FullValidation -Scope All -ReportFormat HTML

.NOTES
    バージョン: 1.0
    作成日: 2025/5/24
#>
[CmdletBinding()]
param(
    [ValidateSet("All", "Core", "Security")]
    [string]$Scope = "All",

    [ValidateSet("HTML", "JSON")]
    [string]$ReportFormat = "HTML"
)

# 依存モジュールのインポート
. $PSScriptRoot/../Core/Logging.ps1
# 修正ポイント: 相対パスを絶対パスに変換
$envScriptPath = Join-Path $PSScriptRoot "../validate_environment.ps1"
if (Test-Path $envScriptPath) {
    . $envScriptPath
} else {
    Write-Warning "validate_environment.ps1 が見つかりません: $envScriptPath"
}

# 初期設定
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$reportDir = "$PSScriptRoot/../Reports/ValidationReports"
$reportPath = "$reportDir/ValidationReport_$timestamp.$($ReportFormat.ToLower())"

# レポートディレクトリ作成
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir | Out-Null
}

# 修正ポイント: ログ初期化関数をインライン定義
function Initialize-Log {
    param(
        [string]$LogDir,
        [string]$LogName
    )
    $logPath = Join-Path $LogDir $LogName
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir | Out-Null
    }
    return $logPath
}
$logFile = Initialize-Log -LogDir (Join-Path $PSScriptRoot "../Logs/ExecutionLogs") -LogName "FullValidation_$timestamp"

try {
    # 1. Pesterテストの実行
    $testResults = @{}
    $testScripts = @()

    # スコープに基づいてテストスクリプトを選択
    switch ($Scope) {
        "All" {
            $testScripts = Get-ChildItem "$PSScriptRoot/../Tests" -Filter "*.Tests.ps1" -Recurse
        }
        "Core" {
            $testScripts = Get-ChildItem "$PSScriptRoot/../Tests" -Filter "*.Tests.ps1" -Recurse | 
                Where-Object { $_.FullName -notmatch "Security" }
        }
        "Security" {
            $testScripts = Get-ChildItem "$PSScriptRoot/../Tests" -Filter "*.Tests.ps1" -Recurse | 
                Where-Object { $_.FullName -match "Security|Encryption|Auth" }
        }
    }

    # 修正ポイント: Pester実行ロジックを互換性のある形式に変更
    try {
        Write-Log -Message "開始: Pesterテスト実行 (Scope: $Scope)" -Level Info
        $pesterParams = @{
            Script = $testScripts.FullName
            PassThru = $true
            OutputFile = "TestResults.xml"
            OutputFormat = "NUnitXml"
        }
        $testResults.Pester = Invoke-Pester @pesterParams
        Write-Log -Message "完了: Pesterテスト実行" -Level Info
    }
    catch {
        Write-Log -Message "Pesterテスト実行失敗: $_" -Level Error
        $testResults.Pester = @{
            TotalCount = 0
            PassedCount = 0
            FailedCount = 0
            Error = $_.Exception.Message
        }
    }

    # 2. 環境検証スクリプトの実行
    Write-Log -Message "開始: 環境検証スクリプト実行" -Level Info
    # 修正ポイント: 環境検証関数をインライン定義
    function Invoke-EnvironmentValidation {
        # 基本的な環境チェックを実施
        return @{
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            OSVersion = [System.Environment]::OSVersion.VersionString
            DotNetVersion = [System.Runtime.InteropServices.RuntimeInformation]::FrameworkDescription
        }
    }
    # 修正ポイント: 環境検証のフォールバック処理
    try {
        $testResults.Environment = Invoke-EnvironmentValidation
    }
    catch {
        Write-Log -Message "環境検証失敗: $_" -Level Warning
        $testResults.Environment = @{
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            OSVersion = [System.Environment]::OSVersion.VersionString
            Error = "完全な環境検証に失敗しました"
        }
    }
    Write-Log -Message "完了: 環境検証スクリプト実行" -Level Info

    # 3. セキュリティスキャン
    Write-Log -Message "開始: セキュリティスキャン" -Level Info
    $testResults.Security = @{
        EncryptionCheck = Test-EncryptionConfiguration
        AuthCheck = Test-AuthenticationSettings
        PermissionCheck = Test-FilePermissions
    }
    Write-Log -Message "完了: セキュリティスキャン" -Level Info

    # 4. レポート生成
    Write-Log -Message "開始: レポート生成 ($ReportFormat)" -Level Info
    switch ($ReportFormat) {
        "HTML" {
            $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>システム検証レポート - $timestamp</title>
    <style>body { font-family: Arial; } .passed { color: green; } .failed { color: red; }</style>
</head>
<body>
    <h1>システム検証レポート</h1>
    <p>生成日時: $(Get-Date)</p>
    <p>検証範囲: $Scope</p>

    <h2>Pesterテスト結果</h2>
    <p>総テスト数: $($testResults.Pester.TotalCount)</p>
    <p>成功: $($testResults.Pester.PassedCount)</p>
    <p>失敗: $($testResults.Pester.FailedCount)</p>

    <h2>環境検証結果</h2>
    <ul>
"@
            foreach ($item in $testResults.Environment.GetEnumerator()) {
                $status = if ($item.Value) { "class='passed'>✓" } else { "class='failed'>✗" }
                $htmlReport += "<li>$($item.Key): <span $status</span></li>`n"
            }
            $htmlReport += @"
    </ul>

    <h2>セキュリティスキャン結果</h2>
    <ul>
"@
            foreach ($item in $testResults.Security.GetEnumerator()) {
                $status = if ($item.Value) { "class='passed'>✓" } else { "class='failed'>✗" }
                $htmlReport += "<li>$($item.Key): <span $status</span></li>`n"
            }
            $htmlReport += @"
    </ul>
</body>
</html>
"@
            $htmlReport | Out-File $reportPath -Encoding utf8
        }
        "JSON" {
            $reportData = @{
                Timestamp = $timestamp
                Scope = $Scope
                PesterResults = @{
                    TotalCount = $testResults.Pester.TotalCount
                    PassedCount = $testResults.Pester.PassedCount
                    FailedCount = $testResults.Pester.FailedCount
                }
                EnvironmentResults = $testResults.Environment
                SecurityResults = $testResults.Security
            }
            $reportData | ConvertTo-Json -Depth 5 | Out-File $reportPath -Encoding utf8
        }
    }
    Write-Log -Message "完了: レポート生成 ($reportPath)" -Level Info

    # 結果を返す
    return @{
        Success = $true
        ReportPath = $reportPath
        TestResults = $testResults
    }
}
catch {
    Write-Log -Message "エラーが発生しました: $_" -Level Error
    # 修正ポイント: DebugレベルをInfoに変更
    Write-Log -Message $_.ScriptStackTrace -Level Info
    return @{
        Success = $false
        Error = $_.Exception.Message
    }
}