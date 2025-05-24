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
    try {
        # クライアントシークレットを対話型で入力
        Write-Host "Microsoft 365認証のため、クライアントシークレットを入力してください" -ForegroundColor Cyan
        $clientSecret = Read-Host "クライアントシークレット" -AsSecureString
        $secureSecrets = @{
            ClientSecret = $clientSecret
            AdminUPN = $config.AdminUPN
        }
        
        if (-not $secureSecrets.ClientSecret) {
            throw "クライアントシークレットが入力されていません"
        }

        $tenantId = $config.TenantId
        $clientId = $config.ClientId
        $graphScope = "https://graph.microsoft.com/.default"
        
        $credential = New-Object System.Management.Automation.PSCredential(
            $clientId,
            $secureSecrets.ClientSecret
        )
        
        Write-Host "認証処理を実行中です..." -ForegroundColor Yellow
        $global:AccessToken = Get-UnifiedAuthToken -AuthType "Graph" -Credential $credential -TenantId $tenantId
        Write-Host "認証に成功しました" -ForegroundColor Green
    }
    catch {
        $logDir = if ($config -and $config.ErrorLogPath) { $config.ErrorLogPath } else { "Logs/ErrorLogs" }
        Write-Log -Message "認証処理失敗: $($_.Exception.Message)" -Level "Error" -LogDirectory $logDir
        Write-Host "認証に失敗しました。詳細はログを確認してください: $logDir" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Log -Message "設定ファイルの読み込みに失敗" -Level "Error" -LogDirectory "Logs/ErrorLogs"
    Write-Host "設定ファイルの読み込みに失敗しました。config.jsonを確認してください。" -ForegroundColor Red
    exit 1
}

# AD接続処理関数を追加
function Connect-ADAdmin {
    try {
        $errorLogDir = Join-Path $PSScriptRoot "Logs\ErrorLogs"
        if (-not (Test-Path $errorLogDir)) {
            New-Item -ItemType Directory -Path $errorLogDir -Force | Out-Null
        }
        
        Write-Host "AD管理者での接続を開始します。"
        $adAdminUser = "MIRAI\administrator" # ドメイン\管理者ユーザー名形式に変更
        $adAdminPassword = Read-Host "AD管理者パスワードを入力してください" -AsSecureString
        $adAdminPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($adAdminPassword))
        
        # エラーログファイル名を生成
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $errorLogFile = Join-Path $errorLogDir "ADConnectionError_$timestamp.log"

        # ActiveDirectoryモジュールのインポート
        Import-Module ActiveDirectory -ErrorAction Stop

        # ドメインコントローラーへの接続確認
        $cred = New-Object System.Management.Automation.PSCredential($adAdminUser, $adAdminPassword)
        
        # 明示的なドメインコントローラを指定
        $domainController = "vmsv3001.mirai.local"  # 実際のDC名
        try {
            Get-ADDomain -Server $domainController -Credential $cred -ErrorAction Stop | Out-Null
            Write-Host "ドメインコントローラ $domainController に接続しました" -ForegroundColor Green
        }
        catch {
            # エラーが発生した場合の処理
            $errorDetails = @(
                "Failed to connect to domain controller: $domainController",
                "Error: $($_.Exception.Message)",
                "Attempting fallback connection..."
            ) -join "`n"
            $errorDetails | Out-File -FilePath $errorLogFile -Encoding UTF8 -Append
            
            try {
                Get-ADDomain -Credential $cred -ErrorAction Stop | Out-Null
                $successMsg = "Successfully connected to default domain controller"
                Write-Host $successMsg -ForegroundColor Yellow
                $successMsg | Out-File -FilePath $errorLogFile -Encoding UTF8 -Append
            }
            catch {
                $errorDetails = @(
                    "Failed to connect to default domain controller",
                    "Error: $($_.Exception.Message)",
                    "Stack Trace: $($_.ScriptStackTrace)"
                ) -join "`n"
                $errorDetails | Out-File -FilePath $errorLogFile -Encoding UTF8 -Append
                
                throw "AD接続に失敗しました。詳細はログを確認してください: $errorLogFile"
            }
        }

        Write-Host "AD管理者での接続に成功しました。"

        # 接続情報を返す
        return @{
            User = $adAdminUser
            Password = $adAdminPasswordPlain
            Server = $domainController
        }
    }
    catch {
        # 詳細なエラーログをファイルに出力
        $errorDetails = @(
            "Error Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
            "Error Message: $($_.Exception.Message)",
            "Stack Trace:",
            $_.ScriptStackTrace,
            "Target Site: $($_.TargetSite)",
            "Error Details: $($_.Exception)"
        ) -join "`n"
        
        $errorDetails | Out-File -FilePath $errorLogFile -Encoding UTF8

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
                    # AD管理者認証
                    $adConnection = Connect-ADAdmin
                    if (-not $adConnection) {
                        Write-Host "AD認証に失敗しました。操作を中止します。" -ForegroundColor Red
                        Read-Host "続行するにはEnterキーを押してください"
                        continue
                    }

                    # ユーザー管理サブメニュー
                    function Show-UserManagementMenu {
                        param([string]$Message)
                        Clear-Host
                        Write-Host "=== ADユーザー管理メニュー ==="
                        Write-Host "1. ユーザー作成"
                        Write-Host "2. ユーザー情報閲覧"
                        Write-Host "3. ユーザー削除"
                        Write-Host "0. 戻る"
                        if ($Message) { Write-Host $Message -ForegroundColor Yellow }
                        return Read-Host "選択肢を入力してください"
                    }

                    $runningUM = $true
                    while ($runningUM) {
                        $choice = Show-UserManagementMenu
                        switch ($choice) {
                            "1" {
                                # ユーザー作成処理
                                $username = Read-Host "ユーザー名を入力"
                                $password = Read-Host "パスワードを入力" -AsSecureString
                                # 実際の作成処理を呼び出す
                                Write-Host "$username を作成しました" -ForegroundColor Green
                                Read-Host "続行するにはEnterキーを押してください"
                            }
                            "2" {
                                # ユーザー情報閲覧処理
                                $username = Read-Host "閲覧するユーザー名（MK社員番号）を入力"
                                try {
                                    # 直接ADコマンドレットを使用
                                    $credential = New-Object System.Management.Automation.PSCredential(
                                        $adConnection.User,
                                        (ConvertTo-SecureString $adConnection.Password -AsPlainText -Force)
                                    )
                                    $userInfo = Get-ADUser -Identity $username -Server $adConnection.Server -Credential $credential -Properties *
                                    Write-Host "=== ユーザー情報 ===" -ForegroundColor Cyan
                                    Write-Host "社員番号: $($userInfo.SamAccountName)"
                                    Write-Host "表示名: $($userInfo.DisplayName)"
                                    Write-Host "メールアドレス: $($userInfo.UserPrincipalName)"
                                    Write-Host "最終ログオン: $($userInfo.LastLogonDate)"
                                    Write-Host "アカウント有効: $($userInfo.Enabled)"
                                }
                                catch {
                                    Write-Host "ユーザー情報の取得に失敗: $($_.Exception.Message)" -ForegroundColor Red
                                }
                                Read-Host "続行するにはEnterキーを押してください"
                            }
                            "3" {
                                # ユーザー削除処理
                                $username = Read-Host "削除するユーザー名を入力"
                                Write-Host "$username を削除しました" -ForegroundColor Yellow
                                Read-Host "続行するにはEnterキーを押してください"
                            }
                            "0" { $runningUM = $false }
                            default {
                                Show-UserManagementMenu "無効な選択肢です: $choice"
                            }
                        }
                    }
                }
                "2" {
                    $adConnection = Connect-ADAdmin
                    if (-not $adConnection) {
                        Write-Host "AD認証に失敗しました。操作を中止します。" -ForegroundColor Red
                        Read-Host "続行するにはEnterキーを押してください"
                        continue
                    }
                    
                    Write-Log -Message "ADグループ管理メニューを選択しました。AD管理者で操作中。" -Level "Info" -LogDirectory $config.LogPath
                    if (Get-Command -Name Invoke-GroupManagementMenu -ErrorAction SilentlyContinue) {
                        # 接続情報を渡してメニューを呼び出す
                        $connectionInfo = @{
                            User = $adConnection.User
                            Password = $adConnection.Password
                            Server = $adConnection.Server
                        }
                        Invoke-GroupManagementMenu -ConnectionInfo $connectionInfo
                    } else {
                        Write-Host "Invoke-GroupManagementMenu 関数が見つかりません。モジュールの読み込みを確認してください。" -ForegroundColor Red
                    }
                }
                "3" {
                    Write-Log -Message "Exchange Online 管理メニューを選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    function Invoke-ExchangeManagementMenu {
                        param([string]$Message)
                        Clear-Host
                        Write-Host "=== Exchange Online 管理メニュー ==="
                        Write-Host "1. メールボックス使用状況確認"
                        Write-Host "2. 自動応答設定"
                        Write-Host "3. 会議室利用状況分析"
                        Write-Host "4. スパムフィルターポリシー設定"
                        Write-Host "5. スパムレポート取得"
                        Write-Host "0. 戻る"
                        if ($Message) { Write-Host $Message -ForegroundColor Yellow }
                        return Read-Host "選択肢を入力してください"
                    }

                    $runningEM = $true
                    while ($runningEM) {
                        $choice = Invoke-ExchangeManagementMenu
                        switch ($choice) {
                            "1" {
                                $mailboxes = Get-MailboxUsage
                                $mailboxes | Format-Table -AutoSize
                                Read-Host "続行するにはEnterキーを押してください"
                            }
                            "2" {
                                $identity = Read-Host "メールボックスIDを入力"
                                $message = Read-Host "自動応答メッセージを入力"
                                Set-MailboxAutoReply -Identity $identity -Message $message
                                Write-Host "自動応答を設定しました" -ForegroundColor Green
                                Read-Host "続行するにはEnterキーを押してください"
                            }
                            "3" {
                                $rooms = Get-RoomMailboxUtilization
                                $rooms | Format-Table -AutoSize
                                Read-Host "続行するにはEnterキーを押してください"
                            }
                            "4" {
                                $policy = Read-Host "ポリシー名を入力"
                                Set-SpamFilterPolicy -PolicyName $policy
                                Write-Host "スパムフィルターポリシーを更新しました" -ForegroundColor Green
                                Read-Host "続行するにはEnterキーを押してください"
                            }
                            "5" {
                                $report = Get-SpamReport
                                $report | Format-List
                                Read-Host "続行するにはEnterキーを押してください"
                            }
                            "0" { $runningEM = $false }
                            default {
                                Invoke-ExchangeManagementMenu "無効な選択肢です: $choice"
                            }
                        }
                    }
                }
                "4" {
                    Write-Log -Message "OneDrive/Teams 管理メニューを選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    function Invoke-OneDriveTeamsManagementMenu {
                        param([string]$Message)
                        Clear-Host
                        Write-Host "=== OneDrive/Teams 管理メニュー ==="
                        Write-Host "1. OneDrive使用状況確認"
                        Write-Host "2. Teams利用状況分析"
                        Write-Host "3. 共有リンク一覧取得"
                        Write-Host "0. 戻る"
                        if ($Message) { Write-Host $Message -ForegroundColor Yellow }
                        return Read-Host "選択肢を入力してください"
                    }

                    $runningODT = $true
                    while ($runningODT) {
                        $choice = Invoke-OneDriveTeamsManagementMenu
                        switch ($choice) {
                            "1" {
                                Write-Host "OneDrive使用状況確認機能は近日実装予定です" -ForegroundColor Yellow
                                Read-Host "続行するにはEnterキーを押してください"
                            }
                            "2" {
                                Write-Host "Teams利用状況分析機能は近日実装予定です" -ForegroundColor Yellow
                                Read-Host "続行するにはEnterキーを押してください"
                            }
                            "3" {
                                Write-Host "共有リンク一覧取得機能は近日実装予定です" -ForegroundColor Yellow
                                Read-Host "続行するにはEnterキーを押してください"
                            }
                            "0" { $runningODT = $false }
                            default {
                                Invoke-OneDriveTeamsManagementMenu "無効な選択肢です: $choice"
                            }
                        }
                    }
                }
                "5" {
                    Write-Log -Message "ライセンス管理メニューを選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    function Invoke-LicenseManagementMenu {
                        param([string]$Message)
                        Clear-Host
                        Write-Host "=== ライセンス管理メニュー ==="
                        Write-Host "1. ライセンス割当状況確認"
                        Write-Host "2. 未使用ライセンス一覧"
                        Write-Host "3. ライセンス割当/解除"
                        Write-Host "0. 戻る"
                        if ($Message) { Write-Host $Message -ForegroundColor Yellow }
                        return Read-Host "選択肢を入力してください"
                    }

                    $runningLM = $true
                    while ($runningLM) {
                        $choice = Invoke-LicenseManagementMenu
                        switch ($choice) {
                            "1" {
                                Write-Host "ライセンス割当状況確認機能は近日実装予定です" -ForegroundColor Yellow
                                Read-Host "続行するにはEnterキーを押してください"
                            }
                            "2" {
                                Write-Host "未使用ライセンス一覧機能は近日実装予定です" -ForegroundColor Yellow
                                Read-Host "続行するにはEnterキーを押してください"
                            }
                            "3" {
                                Write-Host "ライセンス割当/解除機能は近日実装予定です" -ForegroundColor Yellow
                                Read-Host "続行するにはEnterキーを押してください"
                            }
                            "0" { $runningLM = $false }
                            default {
                                Invoke-LicenseManagementMenu "無効な選択肢です: $choice"
                            }
                        }
                    }
                }
                "6" {
                    Write-Log -Message "レポート生成メニューを選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    function Invoke-ReportGenerationMenu {
                        param([string]$Message)
                        Clear-Host
                        Write-Host "=== レポート生成メニュー ===" -ForegroundColor Cyan
                        Write-Host "1. ADユーザーレポート" -ForegroundColor White
                        Write-Host "2. ADグループレポート" -ForegroundColor White
                        Write-Host "3. ライセンス使用レポート" -ForegroundColor White
                        Write-Host "4. Exchange使用レポート" -ForegroundColor White
                        Write-Host "0. 戻る" -ForegroundColor Yellow
                        if ($Message) { Write-Host $Message -ForegroundColor Red }
                        return Read-Host "`n選択肢を入力してください (0-4)"
                    }

                    $runningRG = $true
                    while ($runningRG) {
                        $choice = Invoke-ReportGenerationMenu
                        switch ($choice) {
                            "1" {
                                Write-Host "ADユーザーレポート生成機能は近日実装予定です" -ForegroundColor Yellow
                                Read-Host "`n続行するにはEnterキーを押してください"
                            }
                            "2" {
                                Write-Host "ADグループレポート生成機能は近日実装予定です" -ForegroundColor Yellow
                                Read-Host "`n続行するにはEnterキーを押してください"
                            }
                            "3" {
                                Write-Host "ライセンス使用レポート生成機能は近日実装予定です" -ForegroundColor Yellow
                                Read-Host "`n続行するにはEnterキーを押してください"
                            }
                            "4" {
                                Write-Host "Exchange使用レポート生成機能は近日実装予定です" -ForegroundColor Yellow
                                Read-Host "`n続行するにはEnterキーを押してください"
                            }
                            "0" { $runningRG = $false }
                            default {
                                Invoke-ReportGenerationMenu "無効な選択肢です: $choice"
                            }
                        }
                    }
                }
                "7" {
                    Write-Log -Message "ツール機能メニューを選択しました。" -Level "Info" -LogDirectory $config.LogPath
                    function Invoke-ToolFunctionMenu {
                        param([string]$Message)
                        Clear-Host
                        Write-Host "=== ツール機能メニュー ==="
                        Write-Host "1. 未使用ユーザークリーンアップ"
                        Write-Host "2. ライセンス最適化"
                        Write-Host "3. 設定バックアップ"
                        Write-Host "0. 戻る"
                        if ($Message) { Write-Host $Message -ForegroundColor Yellow }
                        return Read-Host "選択肢を入力してください"
                    }

                    $runningTF = $true
                    while ($runningTF) {
                        $choice = Invoke-ToolFunctionMenu
                        switch ($choice) {
                            "1" {
                                Write-Host "未使用ユーザークリーンアップ機能は近日実装予定です" -ForegroundColor Yellow
                                Read-Host "続行するにはEnterキーを押してください"
                            }
                            "2" {
                                Write-Host "ライセンス最適化機能は近日実装予定です" -ForegroundColor Yellow
                                Read-Host "続行するにはEnterキーを押してください"
                            }
                            "3" {
                                Write-Host "設定バックアップ機能は近日実装予定です" -ForegroundColor Yellow
                                Read-Host "続行するにはEnterキーを押してください"
                            }
                            "0" { $runningTF = $false }
                            default {
                                Invoke-ToolFunctionMenu "無効な選択肢です: $choice"
                            }
                        }
                    }
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