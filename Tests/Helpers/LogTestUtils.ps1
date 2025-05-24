<#
.SYNOPSIS
テスト用ログユーティリティモジュール
#>

function New-MockLogEntry {
    [CmdletBinding()]
    param(
        [ValidateSet("Info","Warning","Error")]
        [string]$Level = "Info",
        
        [string]$Message = "Test log message",
        
        [string]$Source = "TestScript"
    )

    # 修正ポイント: テスト用のログエントリを生成
    return [PSCustomObject]@{
        Timestamp = [DateTime]::Now
        Level     = $Level
        Message   = $Message
        Source    = $Source
    }
}

function New-MockLogSeries {
    [CmdletBinding()]
    param(
        [int]$Count = 10,
        [string[]]$Sources = @("TestScript"),
        [double]$ErrorRate = 0.3
    )

    # 修正ポイント: 複数のログエントリを一括生成
    $logs = @()
    1..$Count | ForEach-Object {
        $level = if ((Get-Random) -lt $ErrorRate) { "Error" }
                elseif ((Get-Random) -lt 0.5) { "Warning" }
                else { "Info" }
        
        $source = $Sources | Get-Random
        $message = switch ($level) {
            "Error" { "ERR$(Get-Random -Minimum 1000 -Maximum 9999): Sample error message" }
            "Warning" { "WRN$(Get-Random -Minimum 1000 -Maximum 9999): Sample warning message" }
            default { "INF$(Get-Random -Minimum 1000 -Maximum 9999): Sample info message" }
        }

        $logs += New-MockLogEntry -Level $level -Message $message -Source $source
    }

    return $logs
}

function Initialize-LogTestEnvironment {
    [CmdletBinding()]
    param()

    # テスト用ログディレクトリを設定
    $testLogPath = Join-Path $TestDrive "Logs"
    if (-not (Test-Path $testLogPath)) {
        New-Item -ItemType Directory -Path $testLogPath | Out-Null
    }

    # ログ設定をテスト用に上書き
    Set-LogConfiguration -LogPath $testLogPath -MaxLogSize 1MB
}

function Get-SampleErrorLog {
    [CmdletBinding()]
    param(
        [int]$Count = 5
    )

    # サンプルエラーログを生成
    1..$Count | ForEach-Object {
        New-MockLogEntry -Level "Error" -Message "Error ${_}: Test error message" -Source "TestModule"
    }
}

Export-ModuleMember -Function New-MockLogEntry, New-MockLogSeries, Initialize-LogTestEnvironment, Get-SampleErrorLog