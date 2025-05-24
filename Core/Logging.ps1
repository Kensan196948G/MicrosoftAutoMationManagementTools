# Core/Logging.ps1

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Info", "Warning", "Error", "Audit")]
        [string]$Level = "Info",
        [Parameter(Mandatory=$false)]
        [string]$LogDirectory = "Logs"
    )

    # グローバル設定からログディレクトリを取得（存在する場合）
    if ($global:Config -and $global:Config.LogPath) {
        $LogDirectory = $global:Config.LogPath
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logFileName = "$(Get-Date -Format "yyyyMMdd").log"
    $logDir = if ([string]::IsNullOrEmpty($LogDirectory)) { "Logs" } else { $LogDirectory }
    $logFilePath = Join-Path $logDir $logFileName

    try {
        # ログディレクトリが存在しない場合は作成
        $logDir = if ([string]::IsNullOrEmpty($LogDirectory)) { "Logs" } else { $LogDirectory }
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
            # サブディレクトリも作成 (RunLogs, ErrorLogs, AuditLogs)
            $subDirs = @("RunLogs", "ErrorLogs", "AuditLogs")
            foreach ($subDir in $subDirs) {
                $fullPath = Join-Path $logDir $subDir
                if (-not (Test-Path $fullPath)) {
                    New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
                }
            }
        }

        # ログエントリの作成
        $logEntry = "[$timestamp] [$Level] $Message"

        # 詳細なログ書き込み
        $logDetails = @(
            "Timestamp: $timestamp",
            "Level: $Level",
            "Message: $Message",
            "LogDirectory: $logDir",
            "CallStack: $(Get-PSCallStack | Out-String)"
        ) -join "`n"
        
        if (-not [string]::IsNullOrEmpty($logFilePath)) {
            Add-Content -Path $logFilePath -Value "=== Log Entry ==="
            Add-Content -Path $logFilePath -Value $logDetails
            Add-Content -Path $logFilePath -Value "================"
        }
        else {
            Write-Error "ログファイルパスが無効です: $logFilePath"
        }
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