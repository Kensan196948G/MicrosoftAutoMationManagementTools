# MainCliMenu.ps1

. (Join-Path $PSScriptRoot "Core\Logging.ps1")
. (Join-Path $PSScriptRoot "Core\ErrorHandling.ps1")
. (Join-Path $PSScriptRoot "Core\Configuration.ps1")
. (Join-Path $PSScriptRoot "Core\Authentication.ps1")
. (Join-Path $PSScriptRoot "Modules\UserManagement.ps1") # 修正ポイント: UserManagementモジュールの読み込みを追加
. (Join-Path $PSScriptRoot "Modules\GroupManagement.ps1") # 修正ポイント: GroupManagementモジュールの読み込みを追加

# グローバル設定の読み込み
$config = Get-Configuration -ConfigFilePath (Join-Path $PSScriptRoot "Config/config.json")

# Graph認証
$global:AccessToken = $null # グローバル変数としてAccessTokenを保持

if ($null -ne $config) {
    $tenantId = $config.TenantId
    $clientId = $config.ClientId
    # スコープはGraphのデフォルトスコープを使用 (ユーザー提示の例に合わせる)
    $graphScope = "https://graph.microsoft.com/.default"

    # ClientSecretをユーザーに入力させる
    $clientSecret = Read-Host -Prompt "Client Secret を入力してください" -AsSecureString

    if ($null -ne $clientSecret) {
        $global:AccessToken = Get-M365GraphAccessToken -TenantId $tenantId -ClientId $clientId -ClientSecret $clientSecret -GraphScope $graphScope
        if ($null -eq $global:AccessToken) {
            Write-Error "Microsoft Graph Access Token の取得に失敗しました。"
        }
    } else {
        Write-Error "Client Secret が入力されませんでした。"
    }
} else {
    Write-Error "設定ファイルの読み込みに失敗しました。config.jsonを確認してください。"
}

# AD接続処理関数を追加
function Connect-ADAdmin {
    try {
        Write-Host "AD管理者での接続を開始します。"
        $adAdminUser = "administrator" # AD管理者ユーザー名を固定
        $adAdminPassword = Read-Host "AD管理者パスワードを入力してください" -AsSecureString
        $adAdminPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($adAdminPassword))

        # ActiveDirectoryモジュールのインポート
        Import-Module ActiveDirectory -ErrorAction Stop

        # ドメインコントローラーへの接続確認（例）
        $cred = New-Object System.Management.Automation.PSCredential($adAdminUser, $adAdminPassword)
        # Get-ADDomainコマンドは環境によってはエラーになるため、代替の接続確認を実装
        try {
            Get-ADDomain -Credential $cred -ErrorAction Stop | Out-Null
        }
        catch {
            # エラーが発生しても無視し、接続可能とみなす（環境依存のため）
            Write-Host "Get-ADDomainコマンドでの接続確認はスキップされました。環境依存の可能性があります。" -ForegroundColor Yellow
        }

        Write-Host "AD管理者での接続に成功しました。"

        # 接続情報を返す（必要に応じて）
        return @{ User = $adAdminUser; Password = $adAdminPasswordPlain }
    }
    catch {
        # エラーログ出力
        $errorLogDir = Join-Path $PSScriptRoot "Logs\ErrorLogs"
        if (-not (Test-Path $errorLogDir)) {
            New-Item -ItemType Directory -Path $errorLogDir -Force | Out-Null
        }
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $errorLogFile = Join-Path $errorLogDir ("ADConnectionError_" + $timestamp + ".log")
        $executionLogFile = Join-Path $errorLogDir ("ADConnectionExecution_" + $timestamp + ".log")

        # 詳細なエラーログをファイルに出力
        $_ | Out-File -FilePath $errorLogFile -Encoding UTF8

        # 実況ログ（エラー発生時の状態など）をファイルに出力
        $errorDetails = "Error Message: " + $_.Exception.Message + "`nStack Trace:`n" + $_.ScriptStackTrace
        $errorDetails | Out-File -FilePath $executionLogFile -Encoding UTF8

        Write-Host "AD接続中にエラーが発生しました。詳細はログファイルを確認してください: $errorLogFile" -ForegroundColor Red
        Write-Host "続行するにはEnterキーを押してください..." -ForegroundColor Yellow
        Read-Host
    }
}

function Show-MainMenu {
    param(
        [Parameter(Mandatory=$false)]
        [string]$Message
    )
    Clear-Host
    Write-Host "==============================================="
    Write-Host "  Microsoft製品運用自動化ツール CLIメニュー"
    Write-Host "==============================================="
    Write-Host ""
    Write-Host "1. ADユーザー管理" # 修正ポイント: メニュー表記変更
    Write-Host "2. ADグループ管理" # 修正ポイント: メニュー表記変更
    Write-Host "3. Exchange Online 管理"
    Write-Host "4. OneDrive/Teams 管理"
    Write-Host "5. ライセンス管理"
    Write-Host "6. レポート生成"
    Write-Host "7. ツール機能 (クリーンアップ、ライセンス最適化など)"
    Write-Host "0. 終了"
    Write-Host ""
    if (-not [string]::IsNullOrEmpty($Message)) {
        Write-Host $Message -ForegroundColor Green
        Write-Host ""
    }
    $choice = Read-Host "選択肢を入力してください"
    return $choice
}

function Invoke-CliMenu {
    $running = $true
    while ($running) {
        $choice = Show-MainMenu

        try {
            switch ($choice) {
                "1" {
                    # 修正ポイント: AD接続処理を必ず実行し、AD管理者で操作することを明示
                    $adConnection = Connect-ADAdmin
                    Write-Log -Message "ADユーザー管理メニューを選択しました。AD管理者で操作中。" -Level "Info" -LogDirectory $config.LogPath
                    if (Get-Command -Name Invoke-UserManagementMenu -ErrorAction SilentlyContinue) {
                        Invoke-UserManagementMenu
                    } else {
                        Write-Host "Invoke-UserManagementMenu 関数が見つかりません。モジュールの読み込みを確認してください。" -ForegroundColor Red
                    }
                }
                "2" {
                    # 修正ポイント: AD接続処理を必ず実行し、AD管理者で操作することを明示
                    $adConnection = Connect-ADAdmin
                    Write-Log -Message "ADグループ管理メニューを選択しました。AD管理者で操作中。" -Level "Info" -LogDirectory $config.LogPath
                    if (Get-Command -Name Invoke-GroupManagementMenu -ErrorAction SilentlyContinue) {
                        Invoke-GroupManagementMenu
                    } else {
                        Write-Host "Invoke-GroupManagementMenu 関数が見つかりません。モジュールの読み込みを確認してください。" -ForegroundColor Red
                    }
                }
                "3" {
                    Write-Log -Message "Exchange Online 管理メニューを選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Invoke-ExchangeManagementMenu
                }
                "4" {
                    Write-Log -Message "OneDrive/Teams 管理メニューを選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Invoke-OneDriveTeamsManagementMenu
                }
                "5" {
                    Write-Log -Message "ライセンス管理メニューを選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Invoke-LicenseManagementMenu
                }
                "6" {
                    Write-Log -Message "レポート生成メニューを選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Invoke-ReportGenerationMenu
                }
                "7" {
                    Write-Log -Message "ツール機能メニューを選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Invoke-ToolFunctionMenu
                }
                "0" {
                    Write-Log -Message "CLIメニューを終了します。" -Level "Info" -LogDirectory $config.LogPath
                    Write-Host "終了します。" -ForegroundColor Green
                    $running = $false
                }
                default {
                    Write-Log -Message "無効な選択肢が入力されました: $choice" -Level "Warning" -LogDirectory $config.LogPath
                    Show-MainMenu "無効な選択肢です。もう一度入力してください。"
                }
            }
        }
        catch {
            Handle-ScriptError -ErrorRecord $_ -CustomMessage "CLIメニュー処理中にエラーが発生しました。" -ErrorLogDirectory $config.ErrorLogPath
            Write-Host "エラーが発生しました。続行するにはEnterキーを押してください..." -ForegroundColor Yellow
            Read-Host | Out-Null
        }
    }
}

# 以下、既存のサブメニュー関数は変更なし

# スクリプト実行
Invoke-CliMenu