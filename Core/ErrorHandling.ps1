# Core/ErrorHandling.ps1

# グローバルエラー処理設定
# 'Stop' に設定することで、エラー発生時にスクリプトの実行を停止し、catchブロックで捕捉できるようにする
$ErrorActionPreference = "Stop"

function Handle-ScriptError {
    param(
        [Parameter(Mandatory=$true)]
        [object]$ErrorRecord, # $Error[0] または try-catch の $_ を想定
        [Parameter(Mandatory=$false)]
        [string]$CustomMessage = "",
        [Parameter(Mandatory=$true)]
        [string]$ErrorLogDirectory # Logging.ps1 の Write-Log 関数に渡すディレクトリ
    )

    # ログに記録するエラー情報を抽出
    $errorMessage = $ErrorRecord.Exception.Message
    $errorScriptStackTrace = $ErrorRecord.ScriptStackTrace
    $errorCategory = $ErrorRecord.CategoryInfo.Category

    # カスタムメッセージがある場合は追加
    if (-not [string]::IsNullOrEmpty($CustomMessage)) {
        $fullErrorMessage = "$CustomMessage - Original Error: $errorMessage"
    } else {
        $fullErrorMessage = $errorMessage
    }

    # Loggingモジュールがロードされていることを前提に、エラーログを書き込む
    # TODO: Loggingモジュールがロードされているかを確認する仕組みを追加
    Write-Log -Message $fullErrorMessage -Level "Error" -LogDirectory $ErrorLogDirectory
    Write-Log -Message "StackTrace: $errorScriptStackTrace" -Level "Error" -LogDirectory $ErrorLogDirectory
    Write-Log -Message "Error Category: $errorCategory" -Level "Error" -LogDirectory $ErrorLogDirectory

    # ここでエラー通知（メール、Teamsなど）を行うことも可能
    # TODO: エラー通知機能の実装

    # スクリプトの実行を継続するか、終了するかを判断するロジック
    # 現在はエラーをログに記録し、スクリプトの実行を停止させる設定
    # 必要に応じて、致命的なエラーのみ停止し、それ以外は継続するなどの制御を実装可能
    Write-Host "Script execution stopped due to unhandled error. Check error logs for details." -ForegroundColor Red
}

# TODO: Invoke-CommandWithErrorHandling 関数などのラッパーを作成し、より使いやすくする