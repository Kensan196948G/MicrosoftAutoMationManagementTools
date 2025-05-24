# ログ移行スクリプト
# 既存のログファイルを新しい構造に移行

# 修正ポイント: ログ保存先をError/ExecutionLogsに分割
$ErrorLogPath = "Logs\Error"
$ExecutionLogPath = "Logs\ExecutionLogs"

# ディレクトリが存在しない場合は作成
if (-not (Test-Path $ErrorLogPath)) {
    New-Item -ItemType Directory -Path $ErrorLogPath | Out-Null
}
if (-not (Test-Path $ExecutionLogPath)) {
    New-Item -ItemType Directory -Path $ExecutionLogPath | Out-Null
}

# ログファイルを分類して移動
Get-ChildItem -Path "Logs\*.log" | ForEach-Object {
    if ($_.Name -match "Error") {
        Move-Item $_.FullName -Destination $ErrorLogPath
    }
    else {
        Move-Item $_.FullName -Destination $ExecutionLogPath
    }
}

Write-Host "ログファイルの移行が完了しました"