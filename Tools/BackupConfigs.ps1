# Tools/BackupConfigs.ps1

# コアモジュールの読み込み
. (Join-Path $PSScriptRoot "..\Core\Logging.ps1")
. (Join-Path $PSScriptRoot "..\Core\ErrorHandling.ps1")
. (Join-Path $PSScriptRoot "..\Core\Authentication.ps1")

function Backup-ConfigurationFiles {
    param(
        [Parameter(Mandatory=$false)]
        [string]$BackupRoot = ".\Logs\Backups"
    )

    try {
        # AD認証を実行
        $token = Get-UnifiedAuthToken -AuthType "AD" -Credential $global:Config.Backup.Credential
        Write-Log -Message "AD認証成功: 設定バックアップ" -Level "Audit" -LogDirectory $global:Config.LogPath

        # バックアップディレクトリ作成
        $backupDir = Join-Path $BackupRoot (Get-Date -Format "yyyyMMdd")
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }

        # バックアップ対象ファイル
        $filesToBackup = @(
            ".\Config\config.json",
            ".\Config\secrets.enc.json"
        )

        # バックアップ実行
        foreach ($file in $filesToBackup) {
            if (Test-Path $file) {
                $dest = Join-Path $backupDir (Split-Path $file -Leaf)
                Copy-Item -Path $file -Destination $dest -Force
                Write-Log -Message "ファイルをバックアップ: $file -> $dest" -Level "Info" -LogDirectory $global:Config.LogPath
            }
        }

        Write-Log -Message "設定バックアップ完了: $backupDir" -Level "Info" -LogDirectory $global:Config.LogPath
        return $backupDir
    }
    catch {
        Write-Log -Message "設定バックアップ失敗: $($_.Exception.Message)" -Level "Error" -LogDirectory $global:Config.ErrorLogPath
        throw "設定バックアップ中にエラーが発生しました"
    }
}

# モジュール公開
Export-ModuleMember -Function Backup-ConfigurationFiles