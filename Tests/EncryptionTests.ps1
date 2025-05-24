# Encryption Module Tests

# 明示的にモジュールをインポート
$modulePath = Join-Path $PSScriptRoot "../Core/Configuration.ps1"
Import-Module $modulePath -Force -DisableNameChecking

Describe "Encryption Functionality Tests" {
    $testKey = "TestEncryptionKey1234567890"
    $testString = "This is a test string"

    It "Should encrypt and decrypt using DPAPI" {
        $encrypted = ConvertTo-EncryptedString -String $testString -EncryptionKey $testKey -Algorithm DPAPI
        $decrypted = ConvertFrom-EncryptedString -EncryptedString $encrypted -EncryptionKey $testKey -Algorithm DPAPI
        $decrypted | Should Be $testString
    }

    It "Should encrypt and decrypt using AES" {
        $encrypted = ConvertTo-EncryptedString -String $testString -EncryptionKey $testKey -Algorithm AES
        $decrypted = ConvertFrom-EncryptedString -EncryptedString $encrypted -EncryptionKey $testKey -Algorithm AES
        $decrypted | Should Be $testString
    }

    It "Should fail with invalid key" {
        $errorThrown = $false
        try {
            ConvertFrom-EncryptedString -EncryptedString "invalid" -EncryptionKey "wrongkey" | Out-Null
        } catch {
            $errorThrown = $true
        }
        $errorThrown | Should Be $true
    }
}

Describe "Key Rotation Tests" {
    $testKey = "TestEncryptionKey1234567890"
    $testString = "This is a test string"
    $testSecretsPath = "$PSScriptRoot/../Config/secrets.enc.json"

    It "Should rotate encryption key" {
        # テスト用のsecretsファイルを作成
        $testSecrets = @{
            ClientSecret = ConvertTo-EncryptedString -String $testString -EncryptionKey $testKey
            AdminUPN = "test@example.com"
        }
        $testSecrets | ConvertTo-Json | Out-File $testSecretsPath -Encoding UTF8

        $newKey = "NewTestEncryptionKey12345"
        $result = Rotate-EncryptionKey -OldKey $testKey -NewKey $newKey
        $result | Should Be $true

        # 新しい鍵で復号できるか確認
        $secrets = Get-Content $testSecretsPath | ConvertFrom-Json
        $decrypted = ConvertFrom-EncryptedString -EncryptedString $secrets.ClientSecret -EncryptionKey $newKey
        $decrypted | Should Be $testString

        # テスト用ファイルを削除
        Remove-Item $testSecretsPath -ErrorAction SilentlyContinue
    }
}