# Core/Authentication.ps1
# 修正ポイント: エラーメッセージ日本語化とログ形式統一
Import-Module "$PSScriptRoot/../Modules/ErrorMessages.ps1" -Force

class AuthToken {
    [string]$AccessToken
    [datetime]$ExpiresOn
    [string]$TokenType
    [string]$Resource
}

class WinRMSessionOptions {
    [bool]$UseSSL = $true
    [string]$Authentication = "Kerberos"
    [int]$Port = 5986
    [int]$OperationTimeout = 30000
    [int]$SkipCACheck = $false
    [int]$SkipCNCheck = $false
    [int]$SkipRevocationCheck = $false
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

        # ログ出力（$global:Configがnullの場合のフォールバック処理）
        $logDir = if ($global:Config -and $global:Config.LogPath) { $global:Config.LogPath } else { "Logs" }
        Write-Log -Message "認証成功: $AuthType" -Level "Audit" -LogDirectory $logDir
        
        return $token
    }
    catch {
        $errorDir = if ($global:Config -and $global:Config.ErrorLogPath) { $global:Config.ErrorLogPath } else { "Logs/ErrorLogs" }
        $errorCode = if ($_.Exception.Message -match "invalid_client") { "AUTH001" }
                    elseif ($_.Exception.Message -match "expired") { "AUTH002" }
                    else { "AUTH000" }
        
        $errorMsg = Get-ErrorMessage -ErrorCode $errorCode -DefaultMessage $_.Exception.Message
        $logMsg = "[$(Get-Date -Format 'yyyy/MM/dd HH:mm')] [ERROR] [UnifiedAuth] [$errorCode] $errorMsg"
        Write-Log -Message $logMsg -Level "Error" -LogDirectory $errorDir
        throw $errorMsg
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
        # 修正ポイント: SecureStringを直接使用し平文変換を排除
        $Body = @{
            grant_type    = "client_credentials"
            scope         = $GraphScope
            client_id     = $ClientId
            client_secret = $ClientSecret
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
    catch {
        $errorCode = if ($_.Exception.Message -match "invalid_client") { "AUTH001" }
                    elseif ($_.Exception.Message -match "invalid_tenant") { "AUTH003" }
                    else { "AUTH000" }
        
        $errorMsg = Get-ErrorMessage -ErrorCode $errorCode -DefaultMessage $_.Exception.Message
        $logMsg = "[$(Get-Date -Format 'yyyy/MM/dd HH:mm')] [ERROR] [GraphAuth] [$errorCode] $errorMsg"
        Write-Log -Message $logMsg -Level "Error" -LogDirectory $errorDir
        throw $errorMsg
    }
    finally {
        # 修正ポイント: メモリクリア処理を簡素化
        Remove-Variable -Name "Body" -ErrorAction SilentlyContinue
    }
}

function Get-ADAuthToken {
    param(
        [Parameter(Mandatory=$true)]
        [pscredential]$Credential,
        
        [Parameter(Mandatory=$false)]
        [WinRMSessionOptions]$SessionOptions
    )

    $token = [AuthToken]::new()
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        
        if (-not $SessionOptions) {
            $SessionOptions = [WinRMSessionOptions]::new()
        }

        # WinRMセッション作成
        Write-Log -Message "WinRMセッション作成開始: サーバー[vmsv3001.mirai.local]" -Level "Debug" -LogDirectory $global:Config.LogPath
        $session = New-WinRMSession -Credential $Credential -SessionOptions $SessionOptions -Server "vmsv3001.mirai.local"
        Write-Log -Message "WinRMセッション作成成功: セッションID[$($session.Id)]" -Level "Debug" -LogDirectory $global:Config.LogPath
        
        # セッションを利用した認証チェック
        Invoke-Command -Session $session -ScriptBlock {
            Get-ADDomain -Credential $using:Credential -ErrorAction Stop | Out-Null
        }
        
        $token.AccessToken = "AD-" + (New-Guid).Guid
        $token.ExpiresOn = (Get-Date).AddHours(1)
        $token.TokenType = "AD"
        $token.Resource = "ActiveDirectory"

        return $token
    }
    catch {
        $errorCode = if ($_.Exception.Message -match "credential") { "CONN003" }
                    elseif ($_.Exception.Message -match "timeout") { "CONN002" }
                    else { "CONN000" }
        
        $errorMsg = Get-ErrorMessage -ErrorCode $errorCode -DefaultMessage $_.Exception.Message
        $logMsg = "[$(Get-Date -Format 'yyyy/MM/dd HH:mm')] [ERROR] [ADAuth] [$errorCode] $errorMsg"
        Write-Log -Message $logMsg -Level "Error" -LogDirectory $errorDir
        throw $errorMsg
    }
}

function New-WinRMSession {
    param(
        [Parameter(Mandatory=$true)]
        [pscredential]$Credential,
        
        [Parameter(Mandatory=$true)]
        [WinRMSessionOptions]$SessionOptions,
        
        [Parameter(Mandatory=$false)]
        [string]$Server
    )
    
    $sessionParams = @{
        Credential = $Credential
        UseSSL = $SessionOptions.UseSSL
        Authentication = $SessionOptions.Authentication
        Port = $SessionOptions.Port
        OperationTimeout = $SessionOptions.OperationTimeout
        SessionOption = New-WSManSessionOption -SkipCACheck:$SessionOptions.SkipCACheck `
                                              -SkipCNCheck:$SessionOptions.SkipCNCheck `
                                              -SkipRevocationCheck:$SessionOptions.SkipRevocationCheck
    }

    # サーバー指定がある場合は追加
    if (-not [string]::IsNullOrEmpty($Server)) {
        $sessionParams['ComputerName'] = $Server
    }

    try {
        $session = New-PSSession @sessionParams
        return $session
    }
    catch {
        $errorCode = if ($_.Exception.Message -match "credential") { "CONN003" }
                    elseif ($_.Exception.Message -match "timeout") { "CONN002" }
                    else { "CONN000" }
        
        $errorMsg = Get-ErrorMessage -ErrorCode $errorCode -DefaultMessage $_.Exception.Message
        $logMsg = "[$(Get-Date -Format 'yyyy/MM/dd HH:mm')] [ERROR] [WinRMSession] [$errorCode] $errorMsg"
        Write-Log -Message $logMsg -Level "Error" -LogDirectory $errorDir
        throw $errorMsg
    }
}

# トークンキャッシュ用
$global:TokenCache = @{}