# AD接続負荷テストスクリプト

# テスト用認証情報
$testCredential = Get-Credential -Message "負荷テスト用AD認証情報を入力してください"

# テストサーバー
$testServer = "ad-server.example.com"

# 1. 並列接続テスト
Describe "並列接続テスト" {
    It "10並列接続が成功すること" {
        $sessions = @()
        $options = [WinRMSessionOptions]::new()
        
        1..10 | ForEach-Object {
            $sessions += New-WinRMSession -Credential $testCredential -SessionOptions $options -Server $testServer
        }

        $sessions.Count | Should -Be 10
        
        # セッションクリーンアップ
        $sessions | Remove-PSSession
    }
}

# 2. 長時間セッションテスト
Describe "長時間セッションテスト" {
    It "30分間セッションを維持できること" {
        $options = [WinRMSessionOptions]::new()
        $options.OperationTimeout = 1800000 # 30分
        
        $session = New-WinRMSession -Credential $testCredential -SessionOptions $options -Server $testServer
        
        try {
            # セッションがアクティブか定期的に確認
            1..6 | ForEach-Object {
                Start-Sleep -Seconds 300 # 5分間隔
                (Get-PSSession -Id $session.Id).State | Should -Be "Opened"
            }
        }
        finally {
            Remove-PSSession -Session $session
        }
    }
}

# 3. 連続操作テスト
Describe "連続操作テスト" {
    It "100回連続でユーザ操作が成功すること" {
        $testUser = "loadtestuser"
        $options = [WinRMSessionOptions]::new()
        
        1..100 | ForEach-Object {
            $newValue = "LoadTest $_"
            { 
                Set-User -UserName $testUser -DisplayName $newValue `
                         -Credential $testCredential -Server $testServer -SessionOptions $options
            } | Should -Not -Throw
        }
    }
}