# MainCliMenu.ps1

. (Join-Path $PSScriptRoot "Core\Logging.ps1")
. (Join-Path $PSScriptRoot "Core\ErrorHandling.ps1")
. (Join-Path $PSScriptRoot "Core\Configuration.ps1")
. (Join-Path $PSScriptRoot "Core\Authentication.ps1")

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
    Write-Host "1. ユーザー管理"
    Write-Host "2. グループ管理"
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
                    Write-Log -Message "ユーザー管理メニューを選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Invoke-UserManagementMenu
                }
                "2" {
                    Write-Log -Message "グループ管理メニューを選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Invoke-GroupManagementMenu
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
            Start-Sleep -Seconds 3
        }
    }
}

# ユーザー管理サブメニューの関数
function Invoke-UserManagementMenu {
    $runningSubMenu = $true
    while ($runningSubMenu) {
        Clear-Host
        Write-Host "==============================================="
        Write-Host "  ユーザー管理サブメニュー"
        Write-Host "==============================================="
        Write-Host ""
        Write-Host "1. 新規ユーザー作成 (TODO)"
        Write-Host "2. ユーザー情報変更 (TODO)"
        Write-Host "3. ユーザー削除 (TODO)"
        Write-Host "9. メインメニューに戻る"
        Write-Host ""
        $subChoice = Read-Host "選択肢を入力してください"

        try {
            switch ($subChoice) {
                "1" {
                    Write-Log -Message "新規ユーザー作成を選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Write-Host "TODO: 新規ユーザー作成機能を実装" -ForegroundColor Yellow
                    # TODO: Modules/UserManagement.ps1 内の New-User 関数などを呼び出す
                    Start-Sleep -Seconds 2
                }
                "2" {
                    Write-Log -Message "ユーザー情報変更を選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Write-Host "TODO: ユーザー情報変更機能を実装" -ForegroundColor Yellow
                    # TODO: Modules/UserManagement.ps1 内の Set-User 関数などを呼び出す
                    Start-Sleep -Seconds 2
                }
                "3" {
                    Write-Log -Message "ユーザー削除を選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Write-Host "TODO: ユーザー削除機能を実装" -ForegroundColor Yellow
                    # TODO: Modules/UserManagement.ps1 内の Remove-User 関数などを呼び出す
                    Start-Sleep -Seconds 2
                }
                "9" {
                    Write-Log -Message "ユーザー管理サブメニューを終了し、メインメニューに戻ります。" -Level "Info" -LogDirectory $config.LogPath
                    $runningSubMenu = $false
                }
                default {
                    Write-Log -Message "無効な選択肢が入力されました: $subChoice" -Level "Warning" -LogDirectory $config.LogPath
                    Write-Host "無効な選択肢です。もう一度入力してください。" -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
            }
        }
        catch {
            Handle-ScriptError -ErrorRecord $_ -CustomMessage "ユーザー管理サブメニュー処理中にエラーが発生しました。" -ErrorLogDirectory $config.ErrorLogPath
            Start-Sleep -Seconds 3
        }
    }
}

# グループ管理サブメニューの関数
function Invoke-GroupManagementMenu {
    $runningSubMenu = $true
    while ($runningSubMenu) {
        Clear-Host
        Write-Host "==============================================="
        Write-Host "  グループ管理サブメニュー"
        Write-Host "==============================================="
        Write-Host ""
        Write-Host "1. 新規グループ作成 (TODO)"
        Write-Host "2. グループメンバー管理 (TODO)"
        Write-Host "3. グループ情報変更 (TODO)"
        Write-Host "4. グループ削除 (TODO)"
        Write-Host "9. メインメニューに戻る"
        Write-Host ""
        $subChoice = Read-Host "選択肢を入力してください"

        try {
            switch ($subChoice) {
                "1" {
                    Write-Log -Message "新規グループ作成を選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Write-Host "TODO: 新規グループ作成機能を実装" -ForegroundColor Yellow
                    # TODO: Modules/GroupManagement.ps1 内の New-Group 関数などを呼び出す
                    Start-Sleep -Seconds 2
                }
                "2" {
                    Write-Log -Message "グループメンバー管理を選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Write-Host "TODO: グループメンバー管理機能を実装" -ForegroundColor Yellow
                    # TODO: Modules/GroupManagement.ps1 内の Add/Remove-GroupMember 関数などを呼び出す
                    Start-Sleep -Seconds 2
                }
                "3" {
                    Write-Log -Message "グループ情報変更を選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Write-Host "TODO: グループ情報変更機能を実装" -ForegroundColor Yellow
                    # TODO: Modules/GroupManagement.ps1 内の Set-Group 関数などを呼び出す
                    Start-Sleep -Seconds 2
                }
                "4" {
                    Write-Log -Message "グループ削除を選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Write-Host "TODO: グループ削除機能を実装" -ForegroundColor Yellow
                    # TODO: Modules/GroupManagement.ps1 内の Remove-Group 関数などを呼び出す
                    Start-Sleep -Seconds 2
                }
                "9" {
                    Write-Log -Message "グループ管理サブメニューを終了し、メインメニューに戻ります。" -Level "Info" -LogDirectory $config.LogPath
                    $runningSubMenu = $false
                }
                default {
                    Write-Log -Message "無効な選択肢が入力されました: $subChoice" -Level "Warning" -LogDirectory $config.LogPath
                    Write-Host "無効な選択肢です。もう一度入力してください。" -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
            }
        }
        catch {
            Handle-ScriptError -ErrorRecord $_ -CustomMessage "グループ管理サブメニュー処理中にエラーが発生しました。" -ErrorLogDirectory $config.ErrorLogPath
            Start-Sleep -Seconds 3
        }
    }
}

# Exchange Online 管理サブメニューの関数
function Invoke-ExchangeManagementMenu {
    $runningSubMenu = $true
    while ($runningSubMenu) {
        Clear-Host
        Write-Host "==============================================="
        Write-Host "  Exchange Online 管理サブメニュー"
        Write-Host "==============================================="
        Write-Host ""
        Write-Host "1. メールボックス管理 (TODO)"
        Write-Host "2. 配布グループ管理 (TODO)"
        Write-Host "3. メールフロールール管理 (TODO)"
        Write-Host "9. メインメニューに戻る"
        Write-Host ""
        $subChoice = Read-Host "選択肢を入力してください"

        try {
            switch ($subChoice) {
                "1" {
                    Write-Log -Message "メールボックス管理を選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Write-Host "TODO: メールボックス管理機能を実装" -ForegroundColor Yellow
                    # TODO: Modules/ExchangeManagement.ps1 内の Mailbox 関連関数を呼び出す
                    Start-Sleep -Seconds 2
                }
                "2" {
                    Write-Log -Message "配布グループ管理を選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Write-Host "TODO: 配布グループ管理機能を実装" -ForegroundColor Yellow
                    # TODO: Modules/ExchangeManagement.ps1 内の DistributionGroup 関連関数を呼び出す
                    Start-Sleep -Seconds 2
                }
                "3" {
                    Write-Log -Message "メールフロールール管理を選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Write-Host "TODO: メールフロールール管理機能を実装" -ForegroundColor Yellow
                    # TODO: Modules/ExchangeManagement.ps1 内の MailFlowRule 関連関数を呼び出す
                    Start-Sleep -Seconds 2
                }
                "9" {
                    Write-Log -Message "Exchange Online 管理サブメニューを終了し、メインメニューに戻ります。" -Level "Info" -LogDirectory $config.LogPath
                    $runningSubMenu = $false
                }
                default {
                    Write-Log -Message "無効な選択肢が入力されました: $subChoice" -Level "Warning" -LogDirectory $config.LogPath
                    Write-Host "無効な選択肢です。もう一度入力してください。" -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
            }
        }
        catch {
            Handle-ScriptError -ErrorRecord $_ -CustomMessage "Exchange Online 管理サブメニュー処理中にエラーが発生しました。" -ErrorLogDirectory $config.ErrorLogPath
            Start-Sleep -Seconds 3
        }
    }
}

# OneDrive/Teams 管理サブメニューの関数
function Invoke-OneDriveTeamsManagementMenu {
    $runningSubMenu = $true
    while ($runningSubMenu) {
        Clear-Host
        Write-Host "==============================================="
        Write-Host "  OneDrive/Teams 管理サブメニュー"
        Write-Host "==============================================="
        Write-Host ""
        Write-Host "1. OneDrive ストレージ管理 (TODO)"
        Write-Host "2. Teams チーム管理 (TODO)"
        Write-Host "3. Teams 会議室管理 (TODO)"
        Write-Host "9. メインメニューに戻る"
        Write-Host ""
        $subChoice = Read-Host "選択肢を入力してください"

        try {
            switch ($subChoice) {
                "1" {
                    Write-Log -Message "OneDrive ストレージ管理を選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Write-Host "TODO: OneDrive ストレージ管理機能を実装" -ForegroundColor Yellow
                    # TODO: Modules/OneDriveManagement.ps1 内の関数を呼び出す
                    Start-Sleep -Seconds 2
                }
                "2" {
                    Write-Log -Message "Teams チーム管理を選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Write-Host "TODO: Teams チーム管理機能を実装" -ForegroundColor Yellow
                    # TODO: Modules/TeamsManagement.ps1 内の Team 関連関数を呼び出す
                    Start-Sleep -Seconds 2
                }
                "3" {
                    Write-Log -Message "Teams 会議室管理を選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Write-Host "TODO: Teams 会議室管理機能を実装" -ForegroundColor Yellow
                    # TODO: Modules/TeamsManagement.ps1 内の Meeting Room 関連関数を呼び出す
                    Start-Sleep -Seconds 2
                }
                "9" {
                    Write-Log -Message "OneDrive/Teams 管理サブメニューを終了し、メインメニューに戻ります。" -Level "Info" -LogDirectory $config.LogPath
                    $runningSubMenu = $false
                }
                default {
                    Write-Log -Message "無効な選択肢が入力されました: $subChoice" -Level "Warning" -LogDirectory $config.LogPath
                    Write-Host "無効な選択肢です。もう一度入力してください。" -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
            }
        }
        catch {
            Handle-ScriptError -ErrorRecord $_ -CustomMessage "OneDrive/Teams 管理サブメニュー処理中にエラーが発生しました。" -ErrorLogDirectory $config.ErrorLogPath
            Start-Sleep -Seconds 3
        }
    }
}

# ライセンス管理サブメニューの関数
function Invoke-LicenseManagementMenu {
    $runningSubMenu = $true
    while ($runningSubMenu) {
        Clear-Host
        Write-Host "==============================================="
        Write-Host "  ライセンス管理サブメニュー"
        Write-Host "==============================================="
        Write-Host ""
        Write-Host "1. ライセンス割り当て (TODO)"
        Write-Host "2. ライセンス解除 (TODO)"
        Write-Host "3. ライセンスレポート (TODO)"
        Write-Host "9. メインメニューに戻る"
        Write-Host ""
        $subChoice = Read-Host "選択肢を入力してください"

        try {
            switch ($subChoice) {
                "1" {
                    Write-Log -Message "ライセンス割り当てを選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Write-Host "TODO: ライセンス割り当て機能を実装" -ForegroundColor Yellow
                    # TODO: Modules/LicenseManagement.ps1 内の Assign-License 関数などを呼び出す
                    Start-Sleep -Seconds 2
                }
                "2" {
                    Write-Log -Message "ライセンス解除を選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Write-Host "TODO: ライセンス解除機能を実装" -ForegroundColor Yellow
                    # TODO: Modules/LicenseManagement.ps1 内の Remove-License 関数などを呼び出す
                    Start-Sleep -Seconds 2
                }
                "3" {
                    Write-Log -Message "ライセンスレポートを選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Write-Host "TODO: ライセンスレポート機能を実装" -ForegroundColor Yellow
                    # TODO: Modules/LicenseManagement.ps1 内の Get-LicenseReport 関数などを呼び出す
                    Start-Sleep -Seconds 2
                }
                "9" {
                    Write-Log -Message "ライセンス管理サブメニューを終了し、メインメニューに戻ります。" -Level "Info" -LogDirectory $config.LogPath
                    $runningSubMenu = $false
                }
                default {
                    Write-Log -Message "無効な選択肢が入力されました: $subChoice" -Level "Warning" -LogDirectory $config.LogPath
                    Write-Host "無効な選択肢です。もう一度入力してください。" -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
            }
        }
        catch {
            Handle-ScriptError -ErrorRecord $_ -CustomMessage "ライセンス管理サブメニュー処理中にエラーが発生しました。" -ErrorLogDirectory $config.ErrorLogPath
            Start-Sleep -Seconds 3
        }
    }
}

# レポート生成サブメニューの関数
function Invoke-ReportGenerationMenu {
    $runningSubMenu = $true
    while ($runningSubMenu) {
        Clear-Host
        Write-Host "==============================================="
        Write-Host "  レポート生成サブメニュー"
        Write-Host "==============================================="
        Write-Host ""
        Write-Host "1. 日次レポート生成 (TODO)"
        Write-Host "2. 週次レポート生成 (TODO)"
        Write-Host "3. 月次レポート生成 (TODO)"
        Write-Host "4. 年次レポート生成 (TODO)"
        Write-Host "9. メインメニューに戻る"
        Write-Host ""
        $subChoice = Read-Host "選択肢を入力してください"

        try {
            switch ($subChoice) {
                "1" {
                    Write-Log -Message "日次レポート生成を選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Write-Host "TODO: 日次レポート生成機能を実装" -ForegroundColor Yellow
                    # TODO: Reports/Daily/ 関連のスクリプトを呼び出す
                    Start-Sleep -Seconds 2
                }
                "2" {
                    Write-Log -Message "週次レポート生成を選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Write-Host "TODO: 週次レポート生成機能を実装" -ForegroundColor Yellow
                    # TODO: Reports/Weekly/ 関連のスクリプトを呼び出す
                    Start-Sleep -Seconds 2
                }
                "3" {
                    Write-Log -Message "月次レポート生成を選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Write-Host "TODO: 月次レポート生成機能を実装" -ForegroundColor Yellow
                    # TODO: Reports/Monthly/ 関連のスクリプトを呼び出す
                    Start-Sleep -Seconds 2
                }
                "4" {
                    Write-Log -Message "年次レポート生成を選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Write-Host "TODO: 年次レポート生成機能を実装" -ForegroundColor Yellow
                    # TODO: Reports/Annual/ 関連のスクリプトを呼び出す
                    Start-Sleep -Seconds 2
                }
                "9" {
                    Write-Log -Message "レポート生成サブメニューを終了し、メインメニューに戻ります。" -Level "Info" -LogDirectory $config.LogPath
                    $runningSubMenu = $false
                }
                default {
                    Write-Log -Message "無効な選択肢が入力されました: $subChoice" -Level "Warning" -LogDirectory $config.LogPath
                    Write-Host "無効な選択肢です。もう一度入力してください。" -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
            }
        }
        catch {
            Handle-ScriptError -ErrorRecord $_ -CustomMessage "レポート生成サブメニュー処理中にエラーが発生しました。" -ErrorLogDirectory $config.ErrorLogPath
            Start-Sleep -Seconds 3
        }
    }
}

# ツール機能サブメニューの関数
function Invoke-ToolFunctionMenu {
    $runningSubMenu = $true
    while ($runningSubMenu) {
        Clear-Host
        Write-Host "==============================================="
        Write-Host "  ツール機能サブメニュー"
        Write-Host "==============================================="
        Write-Host ""
        Write-Host "1. 古いユーザーのクリーンアップ (TODO)"
        Write-Host "2. ライセンスの最適化 (TODO)"
        Write-Host "3. 設定のバックアップ (TODO)"
        Write-Host "9. メインメニューに戻る"
        Write-Host ""
        $subChoice = Read-Host "選択肢を入力してください"

        try {
            switch ($subChoice) {
                "1" {
                    Write-Log -Message "古いユーザーのクリーンアップを選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Write-Host "TODO: 古いユーザーのクリーンアップ機能を実装" -ForegroundColor Yellow
                    # TODO: Tools/CleanupObsoleteUsers.ps1 を呼び出す
                    Start-Sleep -Seconds 2
                }
                "2" {
                    Write-Log -Message "ライセンスの最適化を選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Write-Host "TODO: ライセンスの最適化機能を実装" -ForegroundColor Yellow
                    # TODO: Tools/LicenseOptimizer.ps1 を呼び出す
                    Start-Sleep -Seconds 2
                }
                "3" {
                    Write-Log -Message "設定のバックアップを選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    Write-Host "TODO: 設定のバックアップ機能を実装" -ForegroundColor Yellow
                    # TODO: Tools/BackupConfigs.ps1 を呼び出す
                    Start-Sleep -Seconds 2
                }
                "9" {
                    Write-Log -Message "ツール機能サブメニューを終了し、メインメニューに戻ります。" -Level "Info" -LogDirectory $config.LogPath
                    $runningSubMenu = $false
                }
                default {
                    Write-Log -Message "無効な選択肢が入力されました: $subChoice" -Level "Warning" -LogDirectory $config.LogPath
                    Write-Host "無効な選択肢です。もう一度入力してください。" -ForegroundColor Red
                    Start-Sleep -Seconds 1
                }
            }
        }
        catch {
            Handle-ScriptError -ErrorRecord $_ -CustomMessage "ツール機能サブメニュー処理中にエラーが発生しました。" -ErrorLogDirectory $config.ErrorLogPath
            Start-Sleep -Seconds 3
        }
    }
}

# スクリプト実行
Invoke-CliMenu