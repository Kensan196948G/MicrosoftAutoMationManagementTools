# ログ出力はCore/Logging.ps1のWrite-Logを使用

function Set-User {
    param(
        [Parameter(Mandatory=$true)]
        [string]$UserName,  # 修正ポイント: エラー処理強化とログ出力追加

        [Parameter(Mandatory=$false)]
        [string]$DisplayName,

        [Parameter(Mandatory=$false)]
        [string]$EmailAddress,

        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory=$true)]
        [string]$Server  # 修正ポイント: 接続先サーバーを指定するパラメータ追加
    )

    # RSATのActive Directoryモジュールが利用可能かチェック
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
    }
    catch {
        Write-Host "Active Directoryモジュールが見つかりません。RSATがインストールされているか確認してください。" -ForegroundColor Red
        Read-Host "エラーが発生しました。Enterキーを押して続行してください。"  # 修正ポイント: ユーザー入力待ち追加
        return
    }

    if ([string]::IsNullOrEmpty($UserName)) {
        Write-Host "UserName パラメータは必須であり、空にできません。" -ForegroundColor Red
        Read-Host "エラーが発生しました。Enterキーを押して続行してください。"  # 修正ポイント: ユーザー入力待ち追加
        return
    }

    try {
        $properties = @{}
        if ($DisplayName) { $properties['DisplayName'] = $DisplayName }
        if ($EmailAddress) { $properties['EmailAddress'] = $EmailAddress }

        if ($properties.Count -eq 0) {
            Write-Host "変更するプロパティが指定されていません。" -ForegroundColor Yellow
            Read-Host "処理を続行するにはEnterキーを押してください。"  # 修正ポイント: ユーザー入力待ち追加
            return
        }

        try {
            Set-ADUser -Identity $UserName @properties -Credential $Credential -Server $Server -ErrorAction Stop
            Write-Host "ユーザー情報を更新しました: $UserName" -ForegroundColor Green
        }
        catch {
            Write-Host "ユーザー情報変更中にエラーが発生しました: $_" -ForegroundColor Red
            # 修正ポイント: 認証情報ミスの可能性がある場合の解説コメント追加
            # 【認証情報ミスの原因例】
            # - Credentialオブジェクトのユーザー名またはパスワードが誤っている
            # - アカウントがロックされている、または権限不足
            # - サーバー側で認証方式が変更された
            # 【解決策】
            # - Credentialの内容を再確認し、正しい資格情報を使用する
            # - アカウント状態を管理者に確認する
            # - サーバーの認証設定を確認し、必要に応じて更新する
            $errorMessage = $_.Exception.Message
            Write-Log -Message "Set-User エラー: $errorMessage" -Level "Error" -LogDirectory $global:Config.ErrorLogPath
            Read-Host "エラーが発生しました。Enterキーを押して続行してください。"
        }
    }
    catch {
        Write-Host "ユーザー情報変更処理中に予期せぬエラーが発生しました: $_" -ForegroundColor Red
        $errorMessage = $_.Exception.Message
        Write-Log -Message "Set-User 予期せぬエラー: $errorMessage" -Level "Error" -LogDirectory $global:Config.ErrorLogPath
        Read-Host "エラーが発生しました。Enterキーを押して続行してください。"
    }
}