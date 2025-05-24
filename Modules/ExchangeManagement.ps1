# Modules/ExchangeManagement.ps1

# コアモジュールの読み込み
. (Join-Path $PSScriptRoot "..\Core\Logging.ps1")
. (Join-Path $PSScriptRoot "..\Core\ErrorHandling.ps1")
. (Join-Path $PSScriptRoot "..\Core\Authentication.ps1")

function Get-MailboxUsage {
    param(
        [Parameter(Mandatory=$false)]
        [string[]]$MailboxIdentities,

        [Parameter(Mandatory=$false)]
        [int]$ThresholdPercent = 80,

        [Parameter(Mandatory=$false)]
        [switch]$IncludeArchive
    )

    try {
        # Exchange Online接続確認 (統一認証使用)
        if (-not (Get-ConnectionStatus -Service "ExchangeOnline")) {
            try {
                $token = Get-UnifiedAuthToken -AuthType "Graph" -Credential $global:Config.Exchange.Credential
                Connect-ExchangeOnline -Token $token -Configuration $global:Config.Exchange
            }
            catch {
                Write-Log -Message "Exchange Online認証失敗: $($_.Exception.Message)" -Level "Critical" -LogDirectory $global:Config.ErrorLogPath
                throw
            }
        }

        # メールボックス使用状況取得
        $mailboxes = if ($MailboxIdentities) {
            Get-Mailbox -Identity $MailboxIdentities -ResultSize Unlimited
        } else {
            Get-Mailbox -ResultSize Unlimited
        }

        $results = @()
        foreach ($mailbox in $mailboxes) {
            $stats = Get-MailboxStatistics -Identity $mailbox.Identity
            $usagePercent = [math]::Round(($stats.TotalItemSize.Value.ToBytes() / $mailbox.ProhibitSendQuota.Value.ToBytes()) * 100, 2)

            $result = [PSCustomObject]@{
                Identity = $mailbox.Identity
                DisplayName = $mailbox.DisplayName
                TotalSizeGB = [math]::Round($stats.TotalItemSize.Value.ToGB(), 2)
                QuotaGB = [math]::Round($mailbox.ProhibitSendQuota.Value.ToGB(), 2)
                UsagePercent = $usagePercent
                IsOverThreshold = ($usagePercent -ge $ThresholdPercent)
                ItemCount = $stats.ItemCount
                LastLogonTime = $stats.LastLogonTime
            }

            $results += $result
        }

        # 閾値超過メールボックスのログ記録
        $overThreshold = $results | Where-Object { $_.IsOverThreshold }
        if ($overThreshold) {
            Write-Log -Message "容量閾値超過メールボックス検出: $($overThreshold.Count)件" -Level "Warning" -LogDirectory $global:Config.LogPath
        }

        return $results
    }
    catch {
        Write-Log -Message "メールボックス使用状況取得失敗: $($_.Exception.Message)" -Level "Error" -LogDirectory $global:Config.ErrorLogPath
        throw "メールボックス使用状況取得中にエラーが発生しました"
    }
}

function Set-MailboxAutoReply {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Identity,

        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [datetime]$StartTime,

        [Parameter(Mandatory=$false)]
        [datetime]$EndTime,

        [Parameter(Mandatory=$false)]
        [bool]$ExternalReplyEnabled = $false
    )

    try {
        # Exchange Online接続確認
        if (-not (Get-ConnectionStatus -Service "ExchangeOnline")) {
            Connect-ExchangeOnline -Configuration $global:Config.Exchange
        }

        $params = @{
            Identity = $Identity
            AutoReplyState = "Enabled"
            InternalMessage = $Message
            ExternalMessage = if ($ExternalReplyEnabled) { $Message } else { $null }
        }

        if ($StartTime -and $EndTime) {
            $params.Add("StartTime", $StartTime)
            $params.Add("EndTime", $EndTime)
        }

        Set-MailboxAutoReplyConfiguration @params
        Write-Log -Message "自動応答設定を更新しました: $Identity" -Level "Info" -LogDirectory $global:Config.LogPath
    }
    catch {
        Write-Log -Message "自動応答設定失敗: $($_.Exception.Message)" -Level "Error" -LogDirectory $global:Config.ErrorLogPath
        throw "自動応答設定中にエラーが発生しました"
    }
}

function Get-RoomMailboxUtilization {
    param(
        [Parameter(Mandatory=$false)]
        [string[]]$RoomMailboxIdentities,

        [Parameter(Mandatory=$false)]
        [datetime]$StartDate = (Get-Date).AddDays(-30),

        [Parameter(Mandatory=$false)]
        [datetime]$EndDate = (Get-Date)
    )

    try {
        if (-not (Get-ConnectionStatus -Service "ExchangeOnline")) {
            Connect-ExchangeOnline -Configuration $global:Config.Exchange
        }

        $mailboxes = if ($RoomMailboxIdentities) {
            Get-Mailbox -Identity $RoomMailboxIdentities -ResultSize Unlimited -RecipientTypeDetails RoomMailbox
        } else {
            Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails RoomMailbox
        }

        $results = @()
        foreach ($mailbox in $mailboxes) {
            $calendar = Get-CalendarProcessing -Identity $mailbox.Identity
            $bookingStats = Get-MailboxFolderStatistics -Identity $mailbox.Identity -FolderScope Calendar |
                            Where-Object { $_.Name -eq "Calendar" }

            $daysInPeriod = ($EndDate - $StartDate).TotalDays
            $availabilityPercent = if ($daysInPeriod -gt 0 -and $bookingStats.TotalItems -gt 0) {
                [math]::Round(($bookingStats.TotalItems / $daysInPeriod) * 100, 2)
            } else { 0 }

            $result = [PSCustomObject]@{
                Identity = $mailbox.Identity
                DisplayName = $mailbox.DisplayName
                TotalBookings = $bookingStats.TotalItems
                AutomationProcessing = $calendar.AutomateProcessing
                AvailabilityPercent = $availabilityPercent
                Location = $mailbox.RoomMailboxLocation
                Capacity = $mailbox.RoomMailboxCapacity
                BookingWindow = $calendar.BookingWindowInDays
                LastBookingDate = $bookingStats.LastModifiedTime
            }

            $results += $result
        }

        return $results | Sort-Object AvailabilityPercent -Descending
    }
    catch {
        Write-Log -Message "会議室利用分析失敗: $($_.Exception.Message)" -Level "Error" -LogDirectory $global:Config.ErrorLogPath
        throw "会議室利用分析中にエラーが発生しました"
    }
}

# モジュール公開
function Set-SpamFilterPolicy {
    param(
        [Parameter(Mandatory=$true)]
        [string]$PolicyName,

        [Parameter(Mandatory=$false)]
        [int]$BulkThreshold = 7,

        [Parameter(Mandatory=$false)]
        [int]$PhishThreshold = 7,

        [Parameter(Mandatory=$false)]
        [int]$SpamThreshold = 6,

        [Parameter(Mandatory=$false)]
        [bool]$EnableRegionBlock = $true,

        [Parameter(Mandatory=$false)]
        [string[]]$BlockedRegions = @("CN", "RU", "KP")
    )

    try {
        if (-not (Get-ConnectionStatus -Service "ExchangeOnline")) {
            Connect-ExchangeOnline -Configuration $global:Config.Exchange
        }

        $params = @{
            Identity = $PolicyName
            BulkThreshold = $BulkThreshold
            PhishThreshold = $PhishThreshold
            SpamThreshold = $SpamThreshold
            EnableRegionBlockList = $EnableRegionBlock
            RegionBlockList = $BlockedRegions
        }

        Set-HostedContentFilterPolicy @params
        Write-Log -Message "スパムフィルターポリシーを更新しました: $PolicyName" -Level "Info" -LogDirectory $global:Config.LogPath
    }
    catch {
        Write-Log -Message "スパムフィルターポリシー更新失敗: $($_.Exception.Message)" -Level "Error" -LogDirectory $global:Config.ErrorLogPath
        throw "スパムフィルターポリシー更新中にエラーが発生しました"
    }
}

function Get-SpamReport {
    param(
        [Parameter(Mandatory=$false)]
        [datetime]$StartDate = (Get-Date).AddDays(-7),

        [Parameter(Mandatory=$false)]
        [datetime]$EndDate = (Get-Date)
    )

    try {
        if (-not (Get-ConnectionStatus -Service "ExchangeOnline")) {
            Connect-ExchangeOnline -Configuration $global:Config.Exchange
        }

        $report = Get-HistoricalSearch -ReportType "SpamDetections" -StartDate $StartDate -EndDate $EndDate
        $summary = [PSCustomObject]@{
            TotalMessages = $report.TotalMessageCount
            SpamCount = $report.SpamMessageCount
            PhishCount = $report.PhishMessageCount
            MalwareCount = $report.MalwareMessageCount
            TopSenders = $report.TopSenders | Select-Object -First 5
            TopRecipients = $report.TopRecipients | Select-Object -First 5
            StartDate = $StartDate
            EndDate = $EndDate
        }

        return $summary
    }
    catch {
        Write-Log -Message "スパムレポート取得失敗: $($_.Exception.Message)" -Level "Error" -LogDirectory $global:Config.ErrorLogPath
        throw "スパムレポート取得中にエラーが発生しました"
    }
}

Export-ModuleMember -Function Get-MailboxUsage, Set-MailboxAutoReply, Get-RoomMailboxUtilization, Set-SpamFilterPolicy, Get-SpamReport