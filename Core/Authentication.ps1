# Core/Authentication.ps1

class AuthToken {
    [string]$AccessToken
    [datetime]$ExpiresOn
    [string]$TokenType
    [string]$Resource
}

<#
.SYNOPSIS
統一認証モジュール - Microsoft 365とADの認証を統合
#>
function Get-UnifiedAuthToken {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("Graph", "AD")]
        [string]$AuthType,
        
        [Parameter(Mandatory=$true)]
        [pscredential]$Credential,
        
        [Parameter(Mandatory=$false)]
        [string]$TenantId,
        
        [Parameter(Mandatory=$false)]
        [string]$Resource = "https://graph.microsoft.com"
    )

    try {
        switch ($AuthType) {
            "Graph" {
                $tokenParams = @{
                    TenantId = $TenantId
                    ClientId = $Credential.UserName
                    ClientSecret = $Credential.Password
                    GraphScope = "$Resource/.default"
                }
                $token = Get-M365GraphToken @tokenParams
            }
            "AD" {
                $token = Get-ADAuthToken -Credential $Credential
            }
        }

        # ログ出力
        Write-Log -Message "認証成功: $AuthType" -Level "Audit" -LogDirectory $global:Config.LogPath
        
        return $token
    }
    catch {
        Write-Log -Message "認証失敗: $($_.Exception.Message)" -Level "Error" -LogDirectory $global:Config.ErrorLogPath
        throw
    }
}

function Get-M365GraphToken {
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

    $token = [AuthToken]::new()
    try {
        $clientSecretPlain = ConvertFrom-SecureString -SecureString $ClientSecret -AsPlainText
        $Body = @{
            grant_type    = "client_credentials"
            scope         = $GraphScope
            client_id     = $ClientId
            client_secret = $clientSecretPlain
        }

        $TokenResponse = Invoke-RestMethod -Method Post `
            -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
            -Body $Body

        $token.AccessToken = $TokenResponse.access_token
        $token.ExpiresOn = (Get-Date).AddSeconds($TokenResponse.expires_in)
        $token.TokenType = $TokenResponse.token_type
        $token.Resource = $GraphScope

        return $token
    }
    finally {
        if ($clientSecretPlain) {
            $clientSecretPlain = $null
        }
    }
}

function Get-ADAuthToken {
    param(
        [Parameter(Mandatory=$true)]
        [pscredential]$Credential
    )

    $token = [AuthToken]::new()
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        
        # 簡易的なAD認証チェック
        Get-ADDomain -Credential $Credential -ErrorAction Stop | Out-Null
        
        $token.AccessToken = "AD-" + (New-Guid).Guid
        $token.ExpiresOn = (Get-Date).AddHours(1)
        $token.TokenType = "AD"
        $token.Resource = "ActiveDirectory"

        return $token
    }
    catch {
        throw "AD認証失敗: $($_.Exception.Message)"
    }
}

# トークンキャッシュ用
$global:TokenCache = @{}