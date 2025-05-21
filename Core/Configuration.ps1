# Core/Configuration.ps1

# DPAPIを使用するために必要なアセンブリをロード
# try {
#     Add-Type -AssemblyName System.Security
# }
# catch {
#     Write-Warning "Failed to load System.Security assembly: $($_.Exception.Message)"
# }

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
 
# function Convert-ToEncryptedString {
#     param(
#         [Parameter(Mandatory=$true)]
#         [string]$String,
#         [Parameter(Mandatory=$true)]
#         [string]$EncryptionKey
#     )
#     # 文字列をSecureStringに変換し、EncryptionKeyを基に保護
#     $secureString = $String | ConvertTo-SecureString -AsPlainText -Force
#     # SecureStringを文字列としてエクスポートし、Base64エンコード
#     # Note: Export-ClixmlはXML形式でSecureStringを保存するため、ここでは直接バイト形式で扱わない
#     # 代わりに、EncryptionKeyをパスワードとしてSecureStringを保護
#     $encryptedBytes = [System.Security.Cryptography.ProtectedData]::Protect([System.Text.Encoding]::UTF8.GetBytes($String), [System.Text.Encoding]::UTF8.GetBytes($EncryptionKey), [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
#     return [System.Convert]::ToBase64String($encryptedBytes)
# }
 
# function Convert-ToDecryptedString {
#     param(
#         [Parameter(Mandatory=$true)]
#         [string]$EncryptedString,
#         [Parameter(Mandatory=$true)]
#         [string]$EncryptionKey
#     )
#     try {
#         $encryptedBytes = [System.Convert]::FromBase64String($EncryptedString)
#         $decryptedBytes = [System.Security.Cryptography.ProtectedData]::Unprotect($encryptedBytes, [System.Text.Encoding]::UTF8.GetBytes($EncryptionKey), [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
#         return [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
#     }
#     catch {
#         Write-Error "Failed to decrypt string: $($_.Exception.Message)"
#         return $null
#     }
# }
 
# TODO: config.json と secrets.enc.json のサンプル生成関数
# TODO: secrets.enc.json の暗号化方式（例: DPAPI, AESなど）のより堅牢な実装検討
# TODO: EncryptionKeyの管理方法