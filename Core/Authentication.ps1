# Core/Authentication.ps1

function Get-M365GraphAccessToken {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TenantId,
        [Parameter(Mandatory=$true)]
        [string]$ClientId,
        [Parameter(Mandatory=$true)]
        [securestring]$ClientSecret,
        [Parameter(Mandatory=$false)]
        [string]$GraphScope = "https://graph.microsoft.com/.default"
    )

    try {
        # SecureStringを平文に変換
        $clientSecretPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($ClientSecret)
        )
        # 平文のClientSecretは直ちに使用し、メモリから解放する
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ClientSecret)
        )

        $Body = @{
            grant_type    = "client_credentials"
            scope         = $GraphScope
            client_id     = $ClientId
            client_secret = $clientSecretPlain
        }

        Write-Host "Getting access token for Microsoft Graph..."
        $TokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $Body
        
        # 平文のClientSecretは使用後すぐにクリア
        $clientSecretPlain = $null
        Remove-Variable clientSecretPlain -ErrorAction SilentlyContinue

        Write-Host "Access Token acquired." # AccessToken の先頭一部のみ表示する場合はここを修正
        return $TokenResponse.access_token
    }
    catch {
        Write-Error "Failed to get access token for Microsoft Graph: $($_.Exception.Message)"
        return $null
    }
}

# TODO: トークンのキャッシュとリフレッシュ処理の追加
# TODO: Connect-MgGraph 認証への再検討（必要に応じて）
# TODO: 証明書認証への拡張 (今後の課題)