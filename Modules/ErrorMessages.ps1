New-Module -Name ErrorMessages {
    $ErrorMessages = @{
        AUTH001 = "クライアントシークレットの値が不正です"
        CONN002 = "ADサーバーへの接続がタイムアウトしました"
    }

    function Get-ErrorMessage {
        param($ErrorCode)
        $ErrorMessages[$ErrorCode]
    }

    Export-ModuleMember -Function Get-ErrorMessage -Variable ErrorMessages
}