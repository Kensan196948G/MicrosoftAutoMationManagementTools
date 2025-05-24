# Integrations/WebhookNotifier.ps1

# コアモジュールの読み込み
. (Join-Path $PSScriptRoot "..\Core\Authentication.ps1")

function Send-WebhookNotification {
    param(
        [Parameter(Mandatory=$true)]
        [string]$WebhookUrl,

        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet("Info", "Warning", "Error", "Critical")]
        [string]$Severity = "Info",

        [Parameter(Mandatory=$false)]
        [hashtable]$AdditionalData
    )

    try {
        # ログ記録
        Write-Log -Message "Webhook通知送信開始: $WebhookUrl" -Level "Info" -LogDirectory $global:Config.LogPath

        # リクエストボディ作成
        $body = @{
            timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            message = $Message
            severity = $Severity
        }

        if ($AdditionalData) {
            $body += $AdditionalData
        }

        # 認証トークン取得
        try {
            $token = Get-UnifiedAuthToken -AuthType "Graph" -Credential $global:Config.Webhook.Credential
            
            # HTTPSリクエスト送信
            $params = @{
                Uri = $WebhookUrl
                Method = "Post"
                Body = ($body | ConvertTo-Json -Depth 5)
                ContentType = "application/json"
                Headers = @{
                    Authorization = "Bearer $($token.AccessToken)"
                }
            }
        }
        catch {
            Write-Log -Message "Webhook認証失敗: $($_.Exception.Message)" -Level "Critical" -LogDirectory $global:Config.ErrorLogPath
            throw
        }

        # SSL/TLS 1.2強制
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        $response = Invoke-RestMethod @params

        # ログ記録
        Write-Log -Message "Webhook通知送信成功: $WebhookUrl" -Level "Audit" -LogDirectory $global:Config.LogPath

        return $response
    }
    catch {
        $errorMsg = "Webhook通知失敗: $($_.Exception.Message)"
        Write-Log -Message $errorMsg -Level "Error" -LogDirectory $global:Config.ErrorLogPath
        throw $errorMsg
    }
}

function Test-WebhookConnection {
    param(
        [Parameter(Mandatory=$true)]
        [string]$WebhookUrl
    )

    try {
        # テスト用軽量リクエスト
        $params = @{
            Uri = $WebhookUrl
            Method = "Head"
        }

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $response = Invoke-WebRequest @params -UseBasicParsing

        return ($response.StatusCode -eq 200)
    }
    catch {
        Write-Log -Message "Webhook接続テスト失敗: $($_.Exception.Message)" -Level "Warning" -LogDirectory $global:Config.LogPath
        return $false
    }
}

# モジュール公開
Export-ModuleMember -Function Send-WebhookNotification, Test-WebhookConnection