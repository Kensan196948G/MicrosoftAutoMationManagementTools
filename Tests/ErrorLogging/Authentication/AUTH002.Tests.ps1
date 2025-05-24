# 認証エラーログテストスクリプト
# 修正ポイント: 認証失敗時のログ記録を検証

BeforeAll {
    . $PSScriptRoot/../../../Core/Authentication.ps1
    . $PSScriptRoot/../../../Core/Logging.ps1
}

Describe "AUTH002 - 認証失敗ログ記録テスト" {
    It "無効な認証情報でログが記録されること" {
        # テスト用の無効な認証情報
        $invalidCred = [PSCredential]::new("invalidUser", (ConvertTo-SecureString "wrongPass" -AsPlainText -Force))
        
        # ログ記録をモック
        Mock Write-Log -Verifiable -ParameterFilter {
            $Level -eq "Error" -and $Message -like "*認証失敗*"
        }

        # 認証試行
        { Connect-M365 -Credential $invalidCred } | Should -Throw

        # ログ記録が呼び出されたことを検証
        Assert-MockCalled Write-Log -Exactly 1 -Scope It
    }
}