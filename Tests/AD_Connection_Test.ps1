# AD接続テストスクリプト

# テスト用認証情報
$testCredential = Get-Credential -Message "テスト用AD認証情報を入力してください"

# テストサーバー
$testServer = "ad-server.example.com"

# 1. SSL接続テスト
Describe "SSL接続テスト" {
    It "SSL接続が成功すること" {
        $options = [WinRMSessionOptions]::new()
        $options.UseSSL = $true
        
        { 
            $session = New-WinRMSession -Credential $testCredential -SessionOptions $options -Server $testServer
            Remove-PSSession -Session $session
        } | Should -Not -Throw
    }
}

# 2. 認証方式テスト
Describe "認証方式テスト" {
    It "Kerberos認証が成功すること" {
        $options = [WinRMSessionOptions]::new()
        $options.Authentication = "Kerberos"
        
        { 
            $session = New-WinRMSession -Credential $testCredential -SessionOptions $options -Server $testServer
            Remove-PSSession -Session $session
        } | Should -Not -Throw
    }
}

# 3. エラーハンドリングテスト
Describe "エラーハンドリングテスト" {
    It "無効な認証情報で適切にエラーを処理すること" {
        $invalidCred = Get-Credential -Message "無効な認証情報を入力してください"
        $options = [WinRMSessionOptions]::new()
        
        { 
            New-WinRMSession -Credential $invalidCred -SessionOptions $options -Server $testServer
        } | Should -Throw
    }
}

# 4. ユーザ管理操作テスト
Describe "ユーザ管理操作テスト" {
    It "ユーザ情報更新が成功すること" {
        $testUser = "testuser"
        $newDisplayName = "Test User $(Get-Date -Format 'yyyyMMddHHmmss')"
        
        { 
            Set-User -UserName $testUser -DisplayName $newDisplayName `
                     -Credential $testCredential -Server $testServer
        } | Should -Not -Throw
    }
}