# Tests/Auth_Connection_Test.ps1
# Microsoft365とADの認証・接続検証スクリプト

<#
.SYNOPSIS
Microsoft365とActive Directoryの認証・接続検証スクリプト

.DESCRIPTION
以下のテストを実施:
1. Microsoft365 Graph API認証
2. Active Directory認証
3. 各サービスへの接続検証

.NOTES
セキュリティ要件:
- 認証情報は暗号化された設定ファイルから読み込み
- パスワードはSecureStringで処理
- エラーログは暗号化して保存
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = "$PSScriptRoot/../Config/secrets.enc.json",
    [Parameter(Mandatory=$false)]
    [string]$LogDirectory = "$PSScriptRoot/../Logs"
)

# 設定ファイル存在確認とバリデーション
if (-not (Test-Path $ConfigPath)) {
    throw "設定ファイルが見つかりません: $ConfigPath`n以下のコマンドで生成できます:`n  .\Config\generate_secrets.ps1 -ClientSecret 'YourSecret'"
}

$secretsContent = Get-Content $ConfigPath | ConvertFrom-Json
if (-not $secretsContent.TenantId -or -not $secretsContent.AdminUPN) {
    throw "設定ファイルに必須パラメータ(TenantId, AdminUPN)が不足しています"
}

# ADモジュールチェック
try {
    Import-Module ActiveDirectory -ErrorAction Stop
}
catch {
    Write-Warning "ActiveDirectoryモジュールのロードに失敗: $_`nRSATツールがインストールされているか確認してください"
}

# ログディレクトリ設定
if (-not [string]::IsNullOrEmpty($LogDirectory)) {
    if (-not (Test-Path $LogDirectory)) {
        New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
    }
    $global:Config.LogPath = $LogDirectory
    $global:Config.ErrorLogPath = "$LogDirectory/Errors"
}

# 共通モジュールのインポート
Import-Module "$PSScriptRoot/../Core/Authentication.ps1" -Force
Import-Module "$PSScriptRoot/../Core/Configuration.ps1" -Force
Import-Module "$PSScriptRoot/../Core/Logging.ps1" -Force

# ADテスト用の前提条件チェック
function Test-ADPrerequisites {
    # 管理者権限チェック
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "ADテストには管理者権限が必要です"
    }

    # RSATインストールチェック
    $rsatInstalled = Get-WindowsCapability -Name Rsat.ActiveDirectory* -Online | Where-Object { $_.State -eq 'Installed' }
    if (-not $rsatInstalled) {
        Write-Warning "RSATツールがインストールされていません"
        Write-Host "以下のコマンドでインストールできます:"
        Write-Host "  Get-WindowsCapability -Name Rsat.ActiveDirectory* -Online | Add-WindowsCapability -Online"
        throw "ADテストにはRSATツールが必要です"
    }

    # WinRMサービス状態チェック
    $winrmStatus = Get-Service WinRM
    if ($winrmStatus.Status -ne 'Running') {
        Write-Warning "WinRMサービスが実行されていません"
        Write-Host "以下のコマンドで有効化できます:"
        Write-Host "  Enable-PSRemoting -Force"
        throw "ADテストにはWinRMサービスが必要です"
    }

    return $true
}

# デフォルト設定の初期化
$global:Config = @{
    LogPath = "$PSScriptRoot/../Logs"
    ErrorLogPath = "$PSScriptRoot/../Logs/Errors"
    ConfigPath = "$PSScriptRoot/../Config"
} | ForEach-Object {
    $obj = New-Object PSObject
    $_.GetEnumerator() | ForEach-Object {
        $obj | Add-Member -MemberType NoteProperty -Name $_.Key -Value $_.Value
    }
    $obj
}

# 認証情報取得関数
function Get-EncryptedCredential {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ConfigPath,
        [Parameter(Mandatory=$true)]
        [ValidateSet("M365App","ADAdmin")]
        [string]$Key
    )

    try {
        $secrets = Get-SecureSecrets -SecretsFilePath $ConfigPath
        if (-not $secrets) {
            throw "認証情報の取得に失敗しました"
        }

        switch ($Key) {
            "M365App" {
                $credential = New-Object System.Management.Automation.PSCredential (
                    $secrets.ClientId,
                    $secrets.ClientSecret
                )
            }
            "ADAdmin" {
                $password = ConvertFrom-EncryptedString -EncryptedString $secrets.AdminPassword
                $securePass = ConvertTo-SecureString -String $password -AsPlainText -Force
                $credential = New-Object System.Management.Automation.PSCredential (
                    $secrets.AdminUPN,
                    $securePass
                )
            }
        }

        return $credential
    }
    catch {
        Write-Log -Message "認証情報取得エラー ($Key): $($_.Exception.Message)" -Level Error -LogDirectory $global:Config.ErrorLogPath
        throw
    }
}

# テスト結果クラス
class TestResult {
    [string]$TestName
    [bool]$IsSuccess
    [string]$Details
    [datetime]$TestTime = (Get-Date)
}

# テスト実行関数
function Invoke-AuthConnectionTests {
    [CmdletBinding()]
    param()

    $results = @()

    try {
        # 1. Microsoft365認証テスト
        $m365Result = [TestResult]@{
            TestName = "Microsoft365 Authentication"
        }

        try {
            $m365Cred = Get-EncryptedCredential -ConfigPath $ConfigPath -Key "M365App"
            $graphToken = Get-UnifiedAuthToken -AuthType "Graph" -Credential $m365Cred
            
            # Graph API接続テスト
            $testUri = "https://graph.microsoft.com/v1.0/organization"
            $headers = @{
                Authorization = "Bearer $($graphToken.AccessToken)"
            }
            
            $orgData = Invoke-RestMethod -Uri $testUri -Headers $headers -Method Get
            $m365Result.IsSuccess = $true
            $m365Result.Details = "認証成功: テナントID $($orgData.value[0].id)"
        }
        catch {
            $m365Result.IsSuccess = $false
            $m365Result.Details = "認証失敗: $($_.Exception.Message)"
        }
        $results += $m365Result

        # 2. AD認証テスト
        $adResult = [TestResult]@{
            TestName = "Active Directory Authentication"
        }
        
        # ADテストの前提条件を確認
        try {
            Test-ADPrerequisites | Out-Null
        }
        catch {
            $adResult.IsSuccess = $false
            $adResult.Details = "ADテスト前提条件エラー: $($_.Exception.Message)"
            $results += $adResult
            return $results
        }

        try {
            $adCred = Get-EncryptedCredential -ConfigPath $ConfigPath -Key "ADAdmin"
            $adToken = Get-UnifiedAuthToken -AuthType "AD" -Credential $adCred
            
            # AD接続テスト
            $domainInfo = Get-ADDomain -Credential $adCred
            $adResult.IsSuccess = $true
            $adResult.Details = "認証成功: ドメイン $($domainInfo.DNSRoot)"
        }
        catch {
            $adResult.IsSuccess = $false
            $adResult.Details = "認証失敗: $($_.Exception.Message)"
        }
        $results += $adResult

        # 3. 統合接続テスト
        $combinedResult = [TestResult]@{
            TestName = "Combined Service Access"
        }

        try {
            # M365とADの両方の認証が成功している場合のみ実施
            if ($m365Result.IsSuccess -and $adResult.IsSuccess) {
                # 実際の運用シナリオに近い統合テストを実施
                $testUser = Get-ADUser -Filter {Name -eq "TestUser"} -Credential $adCred
                $graphUser = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/$($testUser.UserPrincipalName)" -Headers $headers
                
                $combinedResult.IsSuccess = $true
                $combinedResult.Details = "統合テスト成功: ユーザー $($testUser.Name) の情報を両システムから取得"
            }
            else {
                $combinedResult.IsSuccess = $false
                $combinedResult.Details = "統合テストスキップ: 基本認証が失敗しています"
            }
        }
        catch {
            $combinedResult.IsSuccess = $false
            $combinedResult.Details = "統合テスト失敗: $($_.Exception.Message)"
        }
        $results += $combinedResult
    }
    catch {
        Write-Log -Message "テスト実行中に予期せぬエラー: $($_.Exception.Message)" -Level Error
        throw
    }

    return $results
}

# テスト結果レポート関数
function Get-TestReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [TestResult[]]$TestResults
    )

    $report = @"
# 認証・接続テストレポート
## 実行日時: $(Get-Date -Format "yyyy/MM/dd HH:mm:ss")

| テスト名 | 結果 | 詳細 |
|----------|------|------|
"@

    foreach ($result in $TestResults) {
        $status = if ($result.IsSuccess) { "✅ 成功" } else { "❌ 失敗" }
        $report += "`n| $($result.TestName) | $status | $($result.Details) |"
    }

    # 全体結果
    $overall = if ($TestResults.IsSuccess -contains $false) { "⚠️ 一部失敗" } else { "✔️ 全成功" }
    $report += "`n`n## 全体結果: $overall"

    return $report
}

# メイン実行ブロック
try {
    $results = Invoke-AuthConnectionTests
    $report = Get-TestReport -TestResults $results
    
    # 結果をコンソールとログに出力
    $report | Out-Host
    $logMessage = "認証テスト実行完了`n$report"
    Write-Log -Message $logMessage -Level Information -LogDirectory $global:Config.LogPath

    # 結果をテキストファイルにも出力
    $reportPath = Join-Path $global:Config.LogPath "AuthTestReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $report | Out-File -FilePath $reportPath -Encoding UTF8

    # ログファイルを自動で開く
    if (Test-Path $reportPath) {
        Start-Process "notepad.exe" -ArgumentList $reportPath -Wait
    }

    # 成功時のみ終了コード0を返す
    if ($results.IsSuccess -contains $false) {
        Write-Warning "一部のテストが失敗しました。詳細はログを確認してください: $reportPath"
        exit 1
    }
    else {
        Write-Host "すべてのテストが成功しました。詳細はログを確認してください: $reportPath" -ForegroundColor Green
        exit 0
    }
}
catch {
    Write-Log -Message "テストスクリプト実行エラー: $($_.Exception.Message)" -Level Error
    exit 2
}