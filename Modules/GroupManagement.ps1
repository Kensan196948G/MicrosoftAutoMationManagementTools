# Modules/GroupManagement.ps1

# モジュール定義
$script:ModuleName = "GroupManagement"
$script:ModuleVersion = "1.2.0"

# 必須モジュールのインポート
. (Join-Path $PSScriptRoot "..\Core\Logging.ps1")
. (Join-Path $PSScriptRoot "..\Core\ErrorHandling.ps1")

function Get-AllADGroups {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$ConnectionInfo
    )
    
    try {
        $credential = New-Object System.Management.Automation.PSCredential(
            $ConnectionInfo.User,
            (ConvertTo-SecureString $ConnectionInfo.Password -AsPlainText -Force)
        )
        
        $groups = Get-ADGroup -Filter * -Server $ConnectionInfo.Server -Credential $credential -Properties Name, GroupScope, GroupCategory, Description |
                  Select-Object Name, GroupScope, GroupCategory, Description, DistinguishedName
        
        return $groups
    }
    catch {
        Write-Log -Message "全グループ取得失敗: $($_.Exception.Message)" -Level "Error"
        throw "グループ一覧の取得に失敗しました"
    }
}

function Get-ADGroupInfo {
    param(
        [Parameter(Mandatory=$true)]
        [string]$GroupName,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$ConnectionInfo
    )
    
    try {
        $credential = New-Object System.Management.Automation.PSCredential(
            $ConnectionInfo.User,
            (ConvertTo-SecureString $ConnectionInfo.Password -AsPlainText -Force)
        )
        
        $group = Get-ADGroup -Identity $GroupName -Server $ConnectionInfo.Server -Credential $credential -Properties *
        $members = Get-ADGroupMember -Identity $GroupName -Server $ConnectionInfo.Server -Credential $credential | 
                   Select-Object Name, SamAccountName, DistinguishedName
        
        return @{
            Group = $group
            Members = $members
        }
    }
    catch {
        Write-Log -Message "グループ情報取得失敗: $($_.Exception.Message)" -Level "Error"
        throw "グループ情報の取得に失敗しました"
    }
}

function Set-ADGroupMembers {
    param(
        [Parameter(Mandatory=$true)]
        [string]$GroupName,
        
        [Parameter(Mandatory=$true)]
        [string[]]$MemberNames,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$ConnectionInfo,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Add","Remove","Replace")]
        [string]$Operation = "Add"
    )
    
    try {
        $credential = New-Object System.Management.Automation.PSCredential(
            $ConnectionInfo.User,
            (ConvertTo-SecureString $ConnectionInfo.Password -AsPlainText -Force)
        )
        
        $members = Get-ADUser -Filter "SamAccountName -in `$MemberNames" -Server $ConnectionInfo.Server -Credential $credential
        
        switch ($Operation) {
            "Add" {
                Add-ADGroupMember -Identity $GroupName -Members $members -Server $ConnectionInfo.Server -Credential $credential
            }
            "Remove" {
                Remove-ADGroupMember -Identity $GroupName -Members $members -Server $ConnectionInfo.Server -Credential $credential -Confirm:$false
            }
            "Replace" {
                Set-ADGroup -Identity $GroupName -Replace @{Member = $members.DistinguishedName} -Server $ConnectionInfo.Server -Credential $credential
            }
        }
        
        Write-Log -Message "グループメンバー更新: $GroupName ($Operation)" -Level "Info"
    }
    catch {
        Write-Log -Message "グループメンバー更新失敗: $($_.Exception.Message)" -Level "Error"
        throw "グループメンバーの更新に失敗しました"
    }
}

function Invoke-GroupManagementMenu {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$ConnectionInfo,
        
        [Parameter(Mandatory=$false)]
        [string]$Message
    )
    
    function Show-GroupMenu {
        param([string]$Msg)
        Clear-Host
        Write-Host ""
        Write-Host "=================================" -ForegroundColor Cyan
        Write-Host "      ADグループ管理メニュー" -ForegroundColor Cyan
        Write-Host "=================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1. グループ情報表示（グループ名指定）" -ForegroundColor White
        Write-Host "2. 全グループ情報表示" -ForegroundColor White
        Write-Host "3. メンバー追加" -ForegroundColor White
        Write-Host "4. メンバー削除" -ForegroundColor White
        Write-Host "5. メンバー一括更新" -ForegroundColor White
        Write-Host "0. 戻る" -ForegroundColor Yellow
        Write-Host ""
        if ($Msg) { 
            Write-Host " [!] $Msg" -ForegroundColor Red
            Write-Host ""
        }
        return Read-Host "選択肢を入力 (0-5)"
    }
    
    $running = $true
    while ($running) {
        $choice = Show-GroupMenu -Msg $Message
        $Message = $null
        
        try {
            switch ($choice) {
                "1" {
                    $groupName = Read-Host "`nグループ名を入力"
                    try {
                        $groupInfo = Get-ADGroupInfo -GroupName $groupName -ConnectionInfo $ConnectionInfo
                        
                        Write-Host "`n=== グループ情報 ===" -ForegroundColor Green
                        $groupInfo.Group | Format-List Name, SamAccountName, GroupScope, GroupCategory, Description
                        
                        Write-Host "`n=== メンバー一覧 ($($groupInfo.Members.Count)名) ===" -ForegroundColor Green
                        $groupInfo.Members | Format-Table -AutoSize
                    }
                    catch {
                        $Message = $_.Exception.Message
                    }
                    Read-Host "`n続行するにはEnterキーを押してください"
                }
                "2" {
                    try {
                        Write-Host "`n全グループ情報を取得中..." -ForegroundColor Yellow
                        $allGroups = Get-AllADGroups -ConnectionInfo $ConnectionInfo
                        
                        Write-Host "`n=== 全グループ一覧 ($($allGroups.Count)グループ) ===" -ForegroundColor Green
                        $allGroups | Format-Table -AutoSize
                    }
                    catch {
                        $Message = $_.Exception.Message
                    }
                    Read-Host "`n続行するにはEnterキーを押してください"
                }
                "3" {
                    $groupName = Read-Host "`nグループ名を入力"
                    $members = Read-Host "追加するメンバー(カンマ区切り)を入力"
                    $memberList = $members -split ',' | ForEach-Object { $_.Trim() }
                    
                    try {
                        Set-ADGroupMembers -GroupName $groupName -MemberNames $memberList -ConnectionInfo $ConnectionInfo -Operation "Add"
                        Write-Host "メンバーを追加しました" -ForegroundColor Green
                    }
                    catch {
                        $Message = $_.Exception.Message
                    }
                    Read-Host "`n続行するにはEnterキーを押してください"
                }
                "4" {
                    $groupName = Read-Host "`nグループ名を入力"
                    $members = Read-Host "削除するメンバー(カンマ区切り)を入力"
                    $memberList = $members -split ',' | ForEach-Object { $_.Trim() }
                    
                    try {
                        Set-ADGroupMembers -GroupName $groupName -MemberNames $memberList -ConnectionInfo $ConnectionInfo -Operation "Remove"
                        Write-Host "メンバーを削除しました" -ForegroundColor Yellow
                    }
                    catch {
                        $Message = $_.Exception.Message
                    }
                    Read-Host "`n続行するにはEnterキーを押してください"
                }
                "5" {
                    $groupName = Read-Host "`nグループ名を輸入"
                    $csvPath = Read-Host "`nメンバー一覧CSVファイルパスを入力"
                    
                    if (-not [string]::IsNullOrEmpty($csvPath) -and (Test-Path $csvPath)) {
                        try {
                            $csvData = Import-Csv $csvPath
                            $memberList = $csvData | Select-Object -ExpandProperty SamAccountName
                            
                            Set-ADGroupMembers -GroupName $groupName -MemberNames $memberList -ConnectionInfo $ConnectionInfo -Operation "Replace"
                            Write-Host "メンバーを一括更新しました" -ForegroundColor Green
                        }
                        catch {
                            $Message = $_.Exception.Message
                        }
                    } else {
                        $Message = "無効なファイルパスです"
                    }
                    Read-Host "`n続行するにはEnterキーを押してください"
                }
                "0" { $running = $false }
                default {
                    $Message = "無効な選択肢です: $choice"
                }
            }
        }
        catch {
            $Message = "システムエラー: $($_.Exception.Message)"
        }
    }
}

# 関数のエクスポート
if ($MyInvocation.MyCommand.CommandType -eq "Script") {
    Export-ModuleMember -Function Invoke-GroupManagementMenu, Get-ADGroupInfo, Get-AllADGroups, Set-ADGroupMembers
}