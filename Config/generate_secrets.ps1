# secrets.enc.json生成/検証スクリプト
param(
    [string]$ClientSecret,
    [string]$AdminUPN = "admin@miraiconst.onmicrosoft.com",
    [switch]$Validate,
    [string]$KeyVaultName,
    [string]$SecretName = "AppEncryptionKey",
    [switch]$UseLocalFallback
)

try {
    # Coreモジュールから暗号化関数をインポート
    . $PSScriptRoot/../Core/Configuration.ps1

    # 修正ポイント: Azure Key Vaultから暗号鍵を取得する関数
    function Get-EncryptionKeyFromVault {
        param(
            [string]$VaultName,
            [string]$SecretName
        )
        
        try {
            $secret = Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName -ErrorAction Stop
            return $secret.SecretValue
        }
        catch {
            Write-Warning "Azure Key Vaultから鍵を取得できませんでした: $_"
            return $null
        }
    }

    # 修正ポイント: ローカルフォールバック用の鍵生成
    function New-LocalEncryptionKey {
        $secureString = Read-Host "Azure Key Vaultに接続できません。ローカル用の暗号鍵を入力してください" -AsSecureString
        return $secureString
    }

    if ($Validate) {
        # 検証モード（変更なし）
        $secretsPath = Join-Path $PSScriptRoot "secrets.enc.json"
        if (-not (Test-Path $secretsPath)) {
            throw "secrets.enc.jsonが見つかりません"
        }

        $secrets = Get-Content $secretsPath | ConvertFrom-Json
        if ($secrets.ClientSecret -eq "ENCRYPTED:PLACEHOLDER") {
            throw "プレースホルダー値が置換されていません"
        }

        Write-Host "検証成功: secrets.enc.jsonは有効です"
        return $true
    }
    else {
        # 生成モード
        if ([string]::IsNullOrEmpty($ClientSecret)) {
            throw "ClientSecretパラメータが必須です"
        }

        # 修正ポイント: 暗号鍵の取得ロジック変更
        $encryptionKey = $null
        
        if (-not $UseLocalFallback -and $KeyVaultName) {
            $encryptionKey = Get-EncryptionKeyFromVault -VaultName $KeyVaultName -SecretName $SecretName
        }

        if (-not $encryptionKey) {
            $encryptionKey = New-LocalEncryptionKey
        }

        # 既存の暗号化処理を新しい鍵で実行
        $encryptedSecret = ConvertTo-EncryptedString -String $ClientSecret -Key $encryptionKey

        $secrets = @{
            TenantId = "your-tenant-id"
            ClientId = "your-client-id"
            ClientSecret = $encryptedSecret
            AdminUPN = $AdminUPN
            AdminPassword = "ENCRYPTED:PLACEHOLDER"
            KeySource = if ($UseLocalFallback) { "Local" } else { "AzureKeyVault" }
        }

        $outputPath = Join-Path $PSScriptRoot "secrets.enc.json"
        $secrets | ConvertTo-Json | Out-File $outputPath -Encoding UTF8
        Write-Host "ファイルを生成しました: $outputPath"
        return $true
    }
}
catch {
    Write-Error "secrets.enc.jsonの生成に失敗: $_"
    return $false
}

# 修正ポイント: 鍵ローテーション用のエントリポイント
function Rotate-EncryptionKey {
    param(
        [string]$KeyVaultName,
        [string]$SecretName = "AppEncryptionKey"
    )
    
    try {
        $newKey = Get-Random -Minimum 100000 -Maximum 999999 | ConvertTo-SecureString -AsPlainText -Force
        Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName -SecretValue $newKey
        Write-Host "暗号鍵をローテーションしました"
        return $true
    }
    catch {
        Write-Error "鍵ローテーションに失敗: $_"
        return $false
    }
}