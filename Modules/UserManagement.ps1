# ログ出力はCore/Logging.ps1のWrite-Logを使用

function Invoke-ADCommand {
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory=$true)]
        [pscredential]$Credential,

        [Parameter(Mandatory=$true)]
        [string]$Server,

        [Parameter(Mandatory=$false)]
        [WinRMSessionOptions]$SessionOptions
    )

    try {
        if (-not $SessionOptions) {
            $SessionOptions = [WinRMSessionOptions]::new()
        }

        $session = New-WinRMSession -Credential $Credential -SessionOptions $SessionOptions -Server $Server
        $result = Invoke-Command -Session $session -ScriptBlock {
            Import-Module ActiveDirectory -ErrorAction Stop
            & $using:ScriptBlock
        }
        
        return $result
    }
    catch {
        Write-Log -Message "ADコマンド実行失敗: $($_.Exception.Message)" -Level "Error" -LogDirectory $global:Config.ErrorLogPath
        throw "AD操作中にエラーが発生しました: $($_.Exception.Message)"
    }
    finally {
        if ($session) {
            Remove-PSSession -Session $session -ErrorAction SilentlyContinue
        }
    }
}

function Set-User {
    param(
        [Parameter(Mandatory=$true)]
        [string]$UserName,

        [Parameter(Mandatory=$false)]
        [string]$DisplayName,

        [Parameter(Mandatory=$false)]
        [string]$EmailAddress,

        [Parameter(Mandatory=$true)]
        [pscredential]$Credential,

        [Parameter(Mandatory=$true)]
        [string]$Server,

        [Parameter(Mandatory=$false)]
        [WinRMSessionOptions]$SessionOptions
    )

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

        $scriptBlock = {
            param($UserName, $properties)
            Set-ADUser -Identity $UserName @properties -ErrorAction Stop
        }

        Invoke-ADCommand -ScriptBlock $scriptBlock -ArgumentList $UserName, $properties `
                        -Credential $Credential -Server $Server -SessionOptions $SessionOptions
        
        Write-Log -Message "ユーザー情報を更新しました: $UserName" -Level "Audit" -LogDirectory $global:Config.LogPath
    }
    catch {
        Write-Host "ユーザー情報変更処理中に予期せぬエラーが発生しました: $_" -ForegroundColor Red
        $errorMessage = $_.Exception.Message
        Write-Log -Message "Set-User 予期せぬエラー: $errorMessage" -Level "Error" -LogDirectory $global:Config.ErrorLogPath
        Read-Host "エラーが発生しました。Enterキーを押して続行してください。"
    }
}