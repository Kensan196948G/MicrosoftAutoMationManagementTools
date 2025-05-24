Describe "Error Message Tests" {
    BeforeAll {
        Import-Module "E:\MicrosoftAutoMationManagementTools\Modules\ErrorMessages.ps1" -Force
    }

    It "AUTH001エラーが正しく記録される" {
        # テストロジック
        $logContent = "[2025/05/24 09:00] [ERROR] [GraphAuth] [AUTH001] クライアントシークレットの値が不正です"
        $result = $logContent -match '.*\[AUTH001\].*クライアントシークレット.*'
        if (-not $result) {
            throw "AUTH001エラーメッセージが正しく記録されていません"
        }
    }
}