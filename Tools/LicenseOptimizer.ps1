# Tools/LicenseOptimizer.ps1

# コアモジュールの読み込み
. (Join-Path $PSScriptRoot "..\Core\Logging.ps1")
. (Join-Path $PSScriptRoot "..\Core\ErrorHandling.ps1")
. (Join-Path $PSScriptRoot "..\Core\Authentication.ps1")

function Optimize-LicenseUsage {
    param(
        [Parameter(Mandatory=$false)]
        [int]$UnusedThresholdDays = 30,
        
        [Parameter(Mandatory=$false)]
        [switch]$WhatIf
    )

    try {
        # Graph API認証を実行
        $token = Get-UnifiedAuthToken -AuthType "Graph" -Credential $global:Config.License.Credential
        Write-Log -Message "Graph認証成功: ライセンス最適化" -Level "Audit" -LogDirectory $global:Config.LogPath

        # ライセンス使用状況を取得
        $licenseUsage = Get-M365LicenseUsage -Token $token
        
        # 未使用ライセンスを検出
        $unusedLicenses = $licenseUsage | Where-Object { 
            $_.LastUsedDate -lt (Get-Date).AddDays(-$UnusedThresholdDays) -and $_.IsAssigned -eq $true
        }
        
        if (-not $unusedLicenses) {
            Write-Log -Message "未使用ライセンスは見つかりませんでした (閾値: $UnusedThresholdDays日)" -Level "Info" -LogDirectory $global:Config.LogPath
            return
        }

        # 最適化レポート作成
        $report = @()
        foreach ($license in $unusedLicenses) {
            $entry = [PSCustomObject]@{
                UserPrincipalName = $license.UserPrincipalName
                LicenseSKU = $license.SkuId
                LastUsedDate = $license.LastUsedDate
                DaysUnused = ((Get-Date) - $license.LastUsedDate).Days
                Action = if ($WhatIf) { "WouldRemove" } else { "Removed" }
            }
            
            if ($WhatIf) {
                Write-Log -Message "[WhatIf] ライセンス削除対象: $($license.UserPrincipalName) (SKU: $($license.SkuId), 未使用日数: $($entry.DaysUnused))" -Level "Info" -LogDirectory $global:Config.LogPath
            }
            else {
                try {
                    # ライセンスを削除
                    Remove-M365LicenseAssignment -Token $token -UserId $license.UserId -SkuId $license.SkuId
                    Write-Log -Message "ライセンスを削除: $($license.UserPrincipalName) (SKU: $($license.SkuId))" -Level "Warning" -LogDirectory $global:Config.LogPath
                }
                catch {
                    $entry.Action = "Failed"
                    Write-Log -Message "ライセンス削除失敗: $($license.UserPrincipalName) - $($_.Exception.Message)" -Level "Error" -LogDirectory $global:Config.ErrorLogPath
                }
            }
            
            $report += $entry
        }

        # レポートをCSV出力
        $reportDate = Get-Date -Format "yyyyMMdd"
        $reportPath = Join-Path $global:Config.ReportPath "LicenseOptimization_$reportDate.csv"
        $report | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8
        
        Write-Log -Message "ライセンス最適化完了: $reportPath" -Level "Info" -LogDirectory $global:Config.LogPath
        return $reportPath
    }
    catch {
        Write-Log -Message "ライセンス最適化失敗: $($_.Exception.Message)" -Level "Critical" -LogDirectory $global:Config.ErrorLogPath
        throw "ライセンス最適化中にエラーが発生しました"
    }
}

# モジュール公開
Export-ModuleMember -Function Optimize-LicenseUsage