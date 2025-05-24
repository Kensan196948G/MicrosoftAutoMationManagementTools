# Core/Logging.ps1

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Info", "Warning", "Error", "Audit")]
        [string]$Level = "Info",
        [Parameter(Mandatory=$false)]
        [string]$BaseLogDirectory = "Logs",
        [Parameter(Mandatory=$false)]
        [string]$ModuleName = "System",
        [Parameter(Mandatory=$false)]
        [string]$ErrorCode = "NONE"
    )

    # グローバル設定からログディレクトリを取得（存在する場合）
    if ($global:Config -and $global:Config.LogPath) {
        $BaseLogDirectory = $global:Config.LogPath
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logFileName = "$(Get-Date -Format "yyyyMMdd").log"

    # ログレベルに応じてログディレクトリを切り替え
    switch ($Level) {
        "Error" {
            $logDir = Join-Path $BaseLogDirectory "ErrorLogs"
        }
        "Info" {
            $logDir = Join-Path $BaseLogDirectory "RunLogs"
        }
        "Warning" {
            $logDir = Join-Path $BaseLogDirectory "RunLogs"
        }
        "Audit" {
            $logDir = Join-Path $BaseLogDirectory "AuditLogs"
        }
        default {
            $logDir = Join-Path $BaseLogDirectory "RunLogs"
        }
    }

    # ログファイルパス
    $logFilePath = Join-Path $logDir $logFileName

    try {
        # ログディレクトリが存在しない場合は作成
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }

        # ログエントリの作成（新しいフォーマット）
        $logEntry = "[$(Get-Date -Format 'yyyy/MM/dd HH:mm')] [$Level] [$ModuleName] [$ErrorCode] $Message"

        # 詳細なログ書き込み
        $logDetails = @(
            "Timestamp: $(Get-Date -Format 'yyyy/MM/dd HH:mm:ss')",
            "Level: $Level",
            "Module: $ModuleName",
            "ErrorCode: $ErrorCode",
            "Message: $Message",
            "LogDirectory: $logDir",
            "CallStack: $(Get-PSCallStack | Out-String)",
            "PSVersion: $($PSVersionTable.PSVersion)",
            "RunAsUser: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
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