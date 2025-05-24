<#
.SYNOPSIS
並列処理ロギングテストスクリプト
#>

BeforeAll {
    # テスト用ログ環境を初期化
    . $PSScriptRoot/../../Helpers/LogTestUtils.ps1
    Initialize-LogTestEnvironment
}

Describe "並列ロギングテスト" {
    It "複数スレッドからの同時ログ書き込み" {
        # テストパラメータ
        $threadCount = 10
        $logCountPerThread = 100
        $testDuration = 30 # 秒

        # ログファイルパス
        $logFile = Join-Path $TestDrive "Logs/concurrent.log"

        # 並列処理用スクリプトブロック
        $logWorker = {
            param($logCount, $logFile)
            1..$logCount | ForEach-Object {
                $logEntry = New-MockLogEntry -Level "Info" -Message "Thread $($PID): Log entry $_"
                $logEntry | Export-Csv -Path $logFile -Append -NoTypeInformation
            }
        }

        # 並列実行
        $jobs = 1..$threadCount | ForEach-Object {
            Start-ThreadJob -ScriptBlock $logWorker -ArgumentList $logCountPerThread, $logFile
        }

        # タイムアウト設定
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        while ($timer.Elapsed.TotalSeconds -lt $testDuration -and ($jobs | Where-Object { $_.State -eq "Running" })) {
            Start-Sleep -Milliseconds 100
        }
        $timer.Stop()

        # ジョブのクリーンアップ
        $jobs | Stop-Job -PassThru | Remove-Job

        # ログの整合性チェック
        $logEntries = Import-Csv -Path $logFile
        $logEntries.Count | Should -Be ($threadCount * $logCountPerThread)
    }

    It "排他制御の検証" {
        # ロックオブジェクト
        $lockObj = [System.Threading.ReaderWriterLockSlim]::new()

        # テスト用カウンタ
        $counter = 0

        # 並列処理用スクリプトブロック
        $incrementWorker = {
            param($lockObj, [ref]$counter)
            try {
                $lockObj.EnterWriteLock()
                $counter.Value++
            }
            finally {
                $lockObj.ExitWriteLock()
            }
        }

        # 並列実行
        $jobs = 1..100 | ForEach-Object {
            Start-ThreadJob -ScriptBlock $incrementWorker -ArgumentList $lockObj, ([ref]$counter)
        }

        # ジョブの完了待機
        $jobs | Wait-Job | Out-Null
        $jobs | Remove-Job

        # 結果検証
        $counter | Should -Be 100
    }
}