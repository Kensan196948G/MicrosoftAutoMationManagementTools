<#
.SYNOPSIS
CI/CDパイプライン環境検証スクリプト
#>

# 必須モジュールとバージョン要件
$moduleRequirements = @{
    "Pester" = @{
        RequiredVersion = "5.3.1"
        Dependencies = @()
    }
    "Microsoft.Graph" = @{
        MinimumVersion = "2.0.0"
        Dependencies = @("Microsoft.Graph.Authentication")
    }
    "AzureAD" = @{
        MinimumVersion = "2.0.2.140"
        Dependencies = @()
    }
}

# 推奨モジュール
$recommendedModules = @(
    "PSScriptAnalyzer",
    "PSFramework"
)

# モジュール検証関数
function Test-ModuleRequirement {
    param(
        [string]$ModuleName,
        [hashtable]$Requirement
    )

    $module = Get-Module -ListAvailable -Name $ModuleName
    if (-not $module) {
        return $false
    }

    if ($Requirement.ContainsKey("RequiredVersion")) {
        return $module.Version -eq [version]$Requirement.RequiredVersion
    }
    elseif ($Requirement.ContainsKey("MinimumVersion")) {
        return $module.Version -ge [version]$Requirement.MinimumVersion
    }

    return $true
}

# モジュールチェック
$missingModules = @()
$versionMismatches = @()
$missingDependencies = @()

foreach ($moduleName in $moduleRequirements.Keys) {
    $requirement = $moduleRequirements[$moduleName]
    
    if (-not (Test-ModuleRequirement -ModuleName $moduleName -Requirement $requirement)) {
        $missingModules += $moduleName
        Write-Warning "必須モジュール $moduleName が要件を満たしていません"
        continue
    }

    # 依存モジュールチェック
    foreach ($dep in $requirement.Dependencies) {
        if (-not (Get-Module -ListAvailable -Name $dep)) {
            $missingDependencies += "$moduleName -> $dep"
            Write-Warning "依存モジュール $dep ($moduleName が必要) が見つかりません"
        }
    }
}

# 推奨モジュールチェック
foreach ($module in $recommendedModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "情報: 推奨モジュール $module がインストールされていません" -ForegroundColor Cyan
    }
}

# テスト環境検証
if (-not (Test-Path ".\Tests")) {
    Write-Error "Testsディレクトリが見つかりません"
    exit 1
}

# 環境変数チェック
if (-not $env:CI_ENVIRONMENT) {
    Write-Warning "CI環境変数が設定されていません"
}

# 結果判定
$hasErrors = $false
if ($missingModules.Count -gt 0) {
    Write-Error "必須モジュールが不足しています: $($missingModules -join ', ')"
    $hasErrors = $true
}

if ($versionMismatches.Count -gt 0) {
    Write-Error "バージョン要件を満たしていないモジュール: $($versionMismatches -join ', ')"
    $hasErrors = $true
}

if ($missingDependencies.Count -gt 0) {
    Write-Error "依存モジュールが不足しています: $($missingDependencies -join ', ')"
    $hasErrors = $true
}

if ($hasErrors) {
    exit 1
}

Write-Output "環境検証が正常に完了しました"
exit 0