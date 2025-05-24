# Scheduler/TaskScheduler.ps1

# コアモジュールの読み込み
. (Join-Path $PSScriptRoot "..\Core\Logging.ps1")
. (Join-Path $PSScriptRoot "..\Core\ErrorHandling.ps1")
. (Join-Path $PSScriptRoot "..\Core\Authentication.ps1")

class ScheduledJob {
    [string]$Name
    [string]$Description
    [string]$ScriptPath
    [timespan]$Interval
    [datetime]$LastRunTime
    [datetime]$NextRunTime
    [bool]$IsEnabled
}

function Register-ScheduledJob {
    param(
        [Parameter(Mandatory=$true)]
        [ScheduledJob]$Job,

        [Parameter(Mandatory=$false)]
        [string]$ConfigPath = ".\Scheduler\job_configs.json"
    )

    try {
        # 既存のジョブ設定を読み込み
        $jobs = @()
        if (Test-Path $ConfigPath) {
            $jobs = Get-Content $ConfigPath | ConvertFrom-Json
        }

        # 重複チェック
        $existingJob = $jobs | Where-Object { $_.Name -eq $Job.Name }
        if ($existingJob) {
            Write-Log -Message "ジョブが既に存在します: $($Job.Name)" -Level "Warning" -LogDirectory $global:Config.LogPath
            return $false
        }

        # 新しいジョブを追加
        $jobs += $Job

        # 設定ファイルに保存
        $jobs | ConvertTo-Json -Depth 5 | Out-File $ConfigPath -Encoding UTF8

        Write-Log -Message "ジョブを登録しました: $($Job.Name)" -Level "Info" -LogDirectory $global:Config.LogPath
        return $true
    }
    catch {
        Write-Log -Message "ジョブ登録失敗: $($_.Exception.Message)" -Level "Error" -LogDirectory $global:Config.ErrorLogPath
        throw "ジョブ登録中にエラーが発生しました"
    }
}

function Start-ScheduledJob {
    param(
        [Parameter(Mandatory=$true)]
        [string]$JobName,

        [Parameter(Mandatory=$false)]
        [string]$ConfigPath = ".\Scheduler\job_configs.json"
    )

    try {
        # ジョブ設定を読み込み
        if (-not (Test-Path $ConfigPath)) {
            throw "ジョブ設定ファイルが見つかりません"
        }

        $jobs = Get-Content $ConfigPath | ConvertFrom-Json
        $job = $jobs | Where-Object { $_.Name -eq $JobName }

        if (-not $job) {
            throw "指定されたジョブが見つかりません: $JobName"
        }

        # AD認証を実行
        $token = Get-UnifiedAuthToken -AuthType "AD" -Credential $global:Config.Scheduler.Credential
        Write-Log -Message "AD認証成功: $JobName" -Level "Audit" -LogDirectory $global:Config.LogPath

        # ジョブスクリプトを実行
        if (Test-Path $job.ScriptPath) {
            Write-Log -Message "ジョブを開始します: $JobName" -Level "Info" -LogDirectory $global:Config.LogPath
            & $job.ScriptPath
            
            $job.LastRunTime = Get-Date
            $job.NextRunTime = $job.LastRunTime + $job.Interval

            # 実行時間を更新
            $jobs | ConvertTo-Json -Depth 5 | Out-File $ConfigPath -Encoding UTF8
        }
        else {
            throw "ジョブスクリプトが見つかりません: $($job.ScriptPath)"
        }
    }
    catch {
        Write-Log -Message "ジョブ実行失敗: $($_.Exception.Message)" -Level "Error" -LogDirectory $global:Config.ErrorLogPath
        throw "ジョブ実行中にエラーが発生しました"
    }
}

function Get-ScheduledJobs {
    param(
        [Parameter(Mandatory=$false)]
        [string]$ConfigPath = ".\Scheduler\job_configs.json"
    )

    try {
        if (Test-Path $ConfigPath) {
            return Get-Content $ConfigPath | ConvertFrom-Json
        }
        return @()
    }
    catch {
        Write-Log -Message "ジョブ一覧取得失敗: $($_.Exception.Message)" -Level "Error" -LogDirectory $global:Config.ErrorLogPath
        throw "ジョブ一覧取得中にエラーが発生しました"
    }
}

# モジュール公開
Export-ModuleMember -Function Register-ScheduledJob, Start-ScheduledJob, Get-ScheduledJobs