# Tools/CleanupObsoleteUsers.ps1

# コアモジュールの読み込み
. (Join-Path $PSScriptRoot "..\Core\Logging.ps1")
. (Join-Path $PSScriptRoot "..\Core\ErrorHandling.ps1")
. (Join-Path $PSScriptRoot "..\Core\Authentication.ps1")

function Remove-ObsoleteUsers {
    param(
        [Parameter(Mandatory=$false)]
        [int]$InactiveDays = 90,
        
        [Parameter(Mandatory=$false)]
        [switch]$WhatIf
    )

    try {
        # AD認証を実行
        $token = Get-UnifiedAuthToken -AuthType "AD" -Credential $global:Config.UserManagement.Credential
        Write-Log -Message "AD認証成功: ユーザークリーンアップ" -Level "Audit" -LogDirectory $global:Config.LogPath

        # 非アクティブユーザーを検出
        $cutoffDate = (Get-Date).AddDays(-$InactiveDays)
        $inactiveUsers = Get-ADUser -Filter {LastLogonDate -lt $cutoffDate -and Enabled -eq $true} -Properties LastLogonDate
        
        if (-not $inactiveUsers) {
            Write-Log -Message "非アクティブユーザーは見つかりませんでした (閾値: $InactiveDays日)" -Level "Info" -LogDirectory $global:Config.LogPath
            return
        }

        # ユーザーリストをログに記録
        Write-Log -Message "非アクティブユーザー検出: $($inactiveUsers.Count)件 (閾値: $InactiveDays日)" -Level "Warning" -LogDirectory $global:Config.LogPath
        
        foreach ($user in $inactiveUsers) {
            if ($WhatIf) {
                Write-Log -Message "[WhatIf] 削除対象ユーザー: $($user.SamAccountName) (最終ログオン: $($user.LastLogonDate))" -Level "Info" -LogDirectory $global:Config.LogPath
            }
            else {
                try {
                    # ユーザーを無効化
                    Disable-ADAccount -Identity $user.DistinguishedName
                    Write-Log -Message "ユーザーを無効化: $($user.SamAccountName)" -Level "Warning" -LogDirectory $global:Config.LogPath
                    
                    # ユーザーを削除
                    Remove-ADUser -Identity $user.DistinguishedName -Confirm:$false
                    Write-Log -Message "ユーザーを削除: $($user.SamAccountName)" -Level "Warning" -LogDirectory $global:Config.LogPath
                }
                catch {
                    Write-Log -Message "ユーザー削除失敗: $($user.SamAccountName) - $($_.Exception.Message)" -Level "Error" -LogDirectory $global:Config.ErrorLogPath
                }
            }
        }

        if (-not $WhatIf) {
            Write-Log -Message "非アクティブユーザークリーンアップ完了: $($inactiveUsers.Count)件" -Level "Info" -LogDirectory $global:Config.LogPath
        }
    }
    catch {
        Write-Log -Message "ユーザークリーンアップ失敗: $($_.Exception.Message)" -Level "Critical" -LogDirectory $global:Config.ErrorLogPath
        throw "ユーザークリーンアップ中にエラーが発生しました"
    }
}

# モジュール公開
Export-ModuleMember -Function Remove-ObsoleteUsers