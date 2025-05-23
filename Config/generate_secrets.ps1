# secrets.enc.json生成スクリプト
param(
    [string]$ClientSecret,
    [string]$AdminUPN = "admin@miraiconst.onmicrosoft.com"
)

try {
    # Coreモジュールから暗号化関数をインポート
    . $PSScriptRoot/../Core/Configuration.ps1

    # 暗号化されたClientSecretを生成
    $encryptedSecret = ConvertTo-EncryptedString -String $ClientSecret

    # secretsオブジェクトを作成
    $secrets = @{
        ClientSecret = $encryptedSecret
        AdminUPN = $AdminUPN
    }

    # JSONに変換して保存 (明示的にConfigディレクトリ指定)
    $outputPath = Join-Path $PSScriptRoot "secrets.enc.json"
    $secrets | ConvertTo-Json | Out-File $outputPath -Encoding UTF8
    Write-Host "ファイルを生成しました: $outputPath"

    Write-Host "secrets.enc.jsonを生成しました"
    return $true
}
catch {
    Write-Error "secrets.enc.jsonの生成に失敗: $_"
    return $false
}