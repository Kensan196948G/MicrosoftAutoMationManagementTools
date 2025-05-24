# secrets.enc.json生成/検証スクリプト
param(
    [string]$ClientSecret,
    [string]$AdminUPN = "admin@miraiconst.onmicrosoft.com",
    [switch]$Validate
)

try {
    # Coreモジュールから暗号化関数をインポート
    . $PSScriptRoot/../Core/Configuration.ps1

    if ($Validate) {
        # 検証モード
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

        $encryptedSecret = ConvertTo-EncryptedString -String $ClientSecret
        $secrets = @{
            TenantId = "your-tenant-id"
            ClientId = "your-client-id"
            ClientSecret = $encryptedSecret
            AdminUPN = $AdminUPN
            AdminPassword = "ENCRYPTED:PLACEHOLDER"
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