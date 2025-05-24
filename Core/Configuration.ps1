# Core/Configuration.ps1

# テスト環境用の簡易ログ関数
if (-not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
    function Write-Log {
        param(
            [string]$Message,
            [string]$Level,
            [string]$LogDirectory
        )
        Write-Host "[$Level] $Message"
    }
}

# DPAPIを使用するために必要なアセンブリをロード
try {
    Add-Type -AssemblyName System.Security
}
catch {
    Write-Log -Message "System.Securityアセンブリのロードに失敗: $($_.Exception.Message)" -Level "Error" -LogDirectory "Logs/ErrorLogs"
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

function Get-SecureSecrets {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SecretsFilePath,
        [Parameter(Mandatory=$false)]
        [string]$EncryptionKey = $env:CONFIG_ENCRYPTION_KEY
    )

    try {
        if (-not (Test-Path $SecretsFilePath)) {
            Write-Error "Secrets file not found: $SecretsFilePath"
            return $null
        }

        $secretsFileContent = Get-Content $SecretsFilePath | ConvertFrom-Json
        
        # ClientSecretの復号
        $decryptedSecret = ConvertFrom-EncryptedString -EncryptedString $secretsFileContent.ClientSecret -EncryptionKey $EncryptionKey
        
        $secureSecrets = @{
            ClientSecret = $decryptedSecret | ConvertTo-SecureString -AsPlainText -Force
            AdminUPN = $secretsFileContent.AdminUPN
        }

        Write-Log -Message "Successfully loaded and secured secrets from $SecretsFilePath" -Level "Info" -LogDirectory $global:Config.LogPath
        return $secureSecrets
    }
    catch {
        Write-Log -Message "Failed to load or secure secrets from ${SecretsFilePath}: $($_.Exception.Message)" -Level "Error" -LogDirectory $global:Config.ErrorLogPath
        return $null
    }
}

function ConvertTo-EncryptedString {
    param(
        [Parameter(Mandatory=$true)]
        [string]$String,
        [Parameter(Mandatory=$false)]
        [string]$EncryptionKey = $env:CONFIG_ENCRYPTION_KEY,
        [Parameter(Mandatory=$false)]
        [ValidateSet('DPAPI','AES')]
        [string]$Algorithm = 'DPAPI'
    )
    
    try {
        if ([string]::IsNullOrEmpty($EncryptionKey)) {
            throw "暗号化キーが指定されていません。環境変数CONFIG_ENCRYPTION_KEYを設定してください。"
        }

        switch ($Algorithm) {
            'DPAPI' {
                $bytesToEncrypt = [System.Text.Encoding]::UTF8.GetBytes($String)
                $entropyBytes = [System.Text.Encoding]::UTF8.GetBytes($EncryptionKey)
                
                $encryptedBytes = [System.Security.Cryptography.ProtectedData]::Protect(
                    $bytesToEncrypt,
                    $entropyBytes,
                    [System.Security.Cryptography.DataProtectionScope]::CurrentUser
                )
                return [System.Convert]::ToBase64String($encryptedBytes)
            }
            'AES' {
                $aes = [System.Security.Cryptography.Aes]::Create()
                $aes.Key = [System.Text.Encoding]::UTF8.GetBytes($EncryptionKey.PadRight(32).Substring(0,32))
                $aes.IV = [System.Text.Encoding]::UTF8.GetBytes($EncryptionKey.PadRight(16).Substring(0,16))
                
                $encryptor = $aes.CreateEncryptor()
                $memoryStream = New-Object System.IO.MemoryStream
                $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($memoryStream, $encryptor, [System.Security.Cryptography.CryptoStreamMode]::Write)
                
                $streamWriter = New-Object System.IO.StreamWriter($cryptoStream)
                $streamWriter.Write($String)
                $streamWriter.Close()
                
                return [System.Convert]::ToBase64String($memoryStream.ToArray())
            }
        }
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
        [string]$EncryptionKey = $env:CONFIG_ENCRYPTION_KEY,
        [Parameter(Mandatory=$false)]
        [ValidateSet('DPAPI','AES')]
        [string]$Algorithm = 'DPAPI'
    )
    
    try {
        if ([string]::IsNullOrEmpty($EncryptionKey)) {
            throw "復号キーが指定されていません。環境変数CONFIG_ENCRYPTION_KEYを設定してください。"
        }

        switch ($Algorithm) {
            'DPAPI' {
                $encryptedBytes = [System.Convert]::FromBase64String($EncryptedString)
                $entropyBytes = [System.Text.Encoding]::UTF8.GetBytes($EncryptionKey)
                
                $decryptedBytes = [System.Security.Cryptography.ProtectedData]::Unprotect(
                    $encryptedBytes,
                    $entropyBytes,
                    [System.Security.Cryptography.DataProtectionScope]::CurrentUser
                )
                return [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
            }
            'AES' {
                try {
                    $aes = [System.Security.Cryptography.Aes]::Create()
                    $aes.Key = [System.Text.Encoding]::UTF8.GetBytes($EncryptionKey.PadRight(32).Substring(0,32))
                    $aes.IV = [System.Text.Encoding]::UTF8.GetBytes($EncryptionKey.PadRight(16).Substring(0,16))
                    
                    $decryptor = $aes.CreateDecryptor()
                    $encryptedBytes = [System.Convert]::FromBase64String($EncryptedString)
                    $memoryStream = New-Object System.IO.MemoryStream @(,$encryptedBytes)
                    $cryptoStream = New-Object System.Security.Cryptography.CryptoStream($memoryStream, $decryptor, [System.Security.Cryptography.CryptoStreamMode]::Read)
                    
                    $streamReader = New-Object System.IO.StreamReader($cryptoStream)
                    return $streamReader.ReadToEnd()
                }
                finally {
                    if ($aes -ne $null) { $aes.Dispose() }
                    if ($memoryStream -ne $null) { $memoryStream.Dispose() }
                    if ($cryptoStream -ne $null) { $cryptoStream.Dispose() }
                    if ($streamReader -ne $null) { $streamReader.Dispose() }
                }
            }
        }
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

function Rotate-EncryptionKey {
    param(
        [Parameter(Mandatory=$true)]
        [string]$OldKey,
        [Parameter(Mandatory=$true)]
        [string]$NewKey,
        [Parameter(Mandatory=$false)]
        [ValidateSet('DPAPI','AES')]
        [string]$Algorithm = 'DPAPI'
    )

    try {
        # 既存のsecrets.enc.jsonを読み込み
        $secretsPath = Join-Path $PSScriptRoot "../Config/secrets.enc.json"
        if (-not (Test-Path $secretsPath)) {
            throw "secrets.enc.jsonが見つかりません"
        }

        $secretsContent = Get-Content $secretsPath | ConvertFrom-Json
        
        # 古い鍵で復号
        $decryptedSecret = ConvertFrom-EncryptedString -EncryptedString $secretsContent.ClientSecret -EncryptionKey $OldKey -Algorithm $Algorithm
        
        # 新しい鍵で再暗号化
        $newEncrypted = ConvertTo-EncryptedString -String $decryptedSecret -EncryptionKey $NewKey -Algorithm $Algorithm
        
        # 更新した内容を保存
        $secretsContent.ClientSecret = $newEncrypted
        $secretsContent | ConvertTo-Json | Out-File $secretsPath -Encoding UTF8
        
        Write-Log -Message "暗号鍵のローテーションが完了しました" -Level "Info" -LogDirectory "Logs"
        return $true
    }
    catch {
        Write-Log -Message "暗号鍵のローテーションに失敗: $($_.Exception.Message)" -Level "Error" -LogDirectory "Logs/ErrorLogs"
        return $false
    }
}

# Export-ModuleMember -Function Get-Configuration, Get-SecureSecrets, ConvertTo-EncryptedString, ConvertFrom-EncryptedString, New-SecureConfigTemplate, Rotate-EncryptionKey