# Core/Configuration.ps1

# DPAPIを使用するために必要なアセンブリをロード
try {
    Add-Type -AssemblyName System.Security
}
catch {
    Write-Log -Message "System.Securityアセンブリのロードに失敗: $($_.Exception.Message)" -Level "Error" -LogDirectory $global:Config.ErrorLogPath
    throw
}

function Get-Configuration {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ConfigFilePath
    )

    try {
        if (-not (Test-Path $ConfigFilePath)) {
            Write-Error "Configuration file not found: $ConfigFilePath"
            return $null
        }
        $configContent = Get-Content $ConfigFilePath | ConvertFrom-Json
        Write-Host "Successfully loaded configuration from $ConfigFilePath."
        return $configContent
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Error "Failed to load configuration from ${ConfigFilePath}: ${errorMessage}"
        return $null
    }
}

# function Get-SecureSecrets {
#     param(
#         [Parameter(Mandatory=$true)]
#         [string]$SecretsFilePath,
#         [Parameter(Mandatory=$true)]
#         [string]$EncryptionKey
#     )

#     try {
#         if (-not (Test-Path $SecretsFilePath)) {
#             Write-Error "Secrets file not found: $SecretsFilePath"
#             return $null
#         }

#         $secretsFileContent = Get-Content $SecretsFilePath | ConvertFrom-Json
#         $encryptedClientSecretValue = $secretsFileContent.ClientSecret
#         $decryptedJson = Convert-ToDecryptedString -EncryptedString $encryptedClientSecretValue -EncryptionKey $EncryptionKey

#         if ($null -eq $decryptedJson) {
#             Write-Error "Failed to decrypt secrets from $SecretsFilePath."
#             return $null
#         }

#         # 複合化したJSON文字列をオブジェクトに変換
#         $secretsContent = $decryptedJson | ConvertFrom-Json
        
#         $secureSecrets = @{}
#         foreach ($key in $secretsContent.PSObject.Properties.Name) {
#             # ClientSecretをSecureStringに変換
#             $secureSecrets[$key] = ($secretsContent.$key | ConvertTo-SecureString -AsPlainText -Force)
#         }
#         Write-Host "Successfully loaded and secured secrets from $SecretsFilePath."
#         return $secureSecrets
#     }
#     catch {
#         $errorMessage = $_.Exception.Message
#         Write-Error "Failed to load or secure secrets from ${SecretsFilePath}: ${errorMessage}"
#         return $null
#     }
# }
 
function ConvertTo-EncryptedString {
    param(
        [Parameter(Mandatory=$true)]
        [string]$String,
        [Parameter(Mandatory=$false)]
        [string]$EncryptionKey = $env:CONFIG_ENCRYPTION_KEY
    )
    
    try {
        if ([string]::IsNullOrEmpty($EncryptionKey)) {
            throw "暗号化キーが指定されていません。環境変数CONFIG_ENCRYPTION_KEYを設定してください。"
        }

        $bytesToEncrypt = [System.Text.Encoding]::UTF8.GetBytes($String)
        $entropyBytes = [System.Text.Encoding]::UTF8.GetBytes($EncryptionKey)
        
        $encryptedBytes = [System.Security.Cryptography.ProtectedData]::Protect(
            $bytesToEncrypt,
            $entropyBytes,
            [System.Security.Cryptography.DataProtectionScope]::CurrentUser
        )
        
        return [System.Convert]::ToBase64String($encryptedBytes)
    }
    catch {
        Write-Log -Message "文字列の暗号化に失敗: $($_.Exception.Message)" -Level "Error" -LogDirectory $global:Config.ErrorLogPath
        throw
    }
}
 
function ConvertFrom-EncryptedString {
    param(
        [Parameter(Mandatory=$true)]
        [string]$EncryptedString,
        [Parameter(Mandatory=$false)]
        [string]$EncryptionKey = $env:CONFIG_ENCRYPTION_KEY
    )
    
    try {
        if ([string]::IsNullOrEmpty($EncryptionKey)) {
            throw "復号キーが指定されていません。環境変数CONFIG_ENCRYPTION_KEYを設定してください。"
        }

        $encryptedBytes = [System.Convert]::FromBase64String($EncryptedString)
        $entropyBytes = [System.Text.Encoding]::UTF8.GetBytes($EncryptionKey)
        
        $decryptedBytes = [System.Security.Cryptography.ProtectedData]::Unprotect(
            $encryptedBytes,
            $entropyBytes,
            [System.Security.Cryptography.DataProtectionScope]::CurrentUser
        )
        
        return [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
    }
    catch {
        Write-Log -Message "文字列の復号に失敗: $($_.Exception.Message)" -Level "Error" -LogDirectory $global:Config.ErrorLogPath
        throw
    }
}
 
function New-SecureConfigTemplate {
    param(
        [Parameter(Mandatory=$true)]
        [string]$OutputDirectory
    )
    
    try {
        # config.jsonテンプレート
        $configTemplate = @{
            TenantId = "your-tenant-id"
            ClientId = "your-client-id"
            LogPath = "Logs/RunLogs"
            ErrorLogPath = "Logs/ErrorLogs"
            AuditLogPath = "Logs/AuditLogs"
            LogLevel = "Normal"
            DefaultScopes = @(
                "User.Read.All",
                "Directory.Read.All"
            )
        }
        
        $configPath = Join-Path $OutputDirectory "config.template.json"
        $configTemplate | ConvertTo-Json -Depth 5 | Out-File $configPath -Encoding UTF8
        
        # secrets.enc.jsonテンプレート (ダミーの暗号化値)
        $secretsTemplate = @{
            ClientSecret = "ENCRYPTED:PLACEHOLDER"
            AdminUPN = "admin@yourdomain.onmicrosoft.com"
        }
        
        $secretsPath = Join-Path $OutputDirectory "secrets.enc.template.json"
        $secretsTemplate | ConvertTo-Json -Depth 3 | Out-File $secretsPath -Encoding UTF8
        
        $logDir = if ($global:Config -and $global:Config.LogPath) { $global:Config.LogPath } else { "Logs" }
        Write-Log -Message "設定ファイルテンプレートを生成しました: $OutputDirectory" -Level "Info" -LogDirectory $logDir
        return $true
    }
    catch {
        $errorDir = if ($global:Config -and $global:Config.ErrorLogPath) { $global:Config.ErrorLogPath } else { "Logs/ErrorLogs" }
        Write-Log -Message "設定ファイルテンプレートの生成に失敗: $($_.Exception.Message)" -Level "Error" -LogDirectory $errorDir
        return $false
    }
}

# Export-ModuleMember -Function Get-Configuration, Get-SecureSecrets, ConvertTo-EncryptedString, ConvertFrom-EncryptedString, New-SecureConfigTemplate