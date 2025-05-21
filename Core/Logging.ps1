# Core/Logging.ps1

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Info", "Warning", "Error", "Audit")]
        [string]$Level = "Info",
        [Parameter(Mandatory=$true)]
        [string]$LogDirectory
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logFileName = "$(Get-Date -Format "yyyyMMdd").log"
    $logFilePath = Join-Path $LogDirectory $logFileName

    try {
        # ログディレクトリが存在しない場合は作成
        if (-not (Test-Path $LogDirectory)) {
            New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
        }

        # ログエントリの作成
        $logEntry = "[$timestamp] [$Level] $Message"

        # ログファイルへの書き込み
        Add-Content -Path $logFilePath -Value $logEntry
        # Write-Host "$logEntry" # デバッグ用
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Error "Failed to write log to ${logFilePath}: ${errorMessage}"
    }
}

# TODO: ログファイルパスの管理（実行ログ、エラーログ、監査ログ）を区別
# TODO: CSV/HTML形式でのログ出力対応
# TODO: ログの保存期間管理（Cleaningジョブを別途作成するか、本モジュールに含めるか検討）