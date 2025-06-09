<#
.SYNOPSIS
pyenv-win 高级管理工具

.DESCRIPTION
提供完整的 pyenv-win 管理解决方案，包括：
- 安装/更新 pyenv-win
- Python 版本管理（安装、切换、查看）
- 环境变量配置
- 可安装版本浏览
- 环境脚本生成

.EXAMPLE
# 交互式菜单模式
.\pyenv-manager.ps1

# 静默安装 Python 版本
.\pyenv-manager.ps1 -InstallPython 3.11.0

# 生成环境激活脚本
.\pyenv-manager.ps1 -GenerateEnvScript
#>

[CmdletBinding(DefaultParameterSetName = 'MenuMode')]
param (
    [Parameter(ParameterSetName = 'SilentInstall')]
    [string]$InstallPython = "",
    
    [Parameter(ParameterSetName = 'GenerateScript')]
    [switch]$GenerateEnvScript,
    
    [Parameter(ParameterSetName = 'SetVersion')]
    [string]$SetLocalVersion = ""
)

# 初始化设置
$Script:PyEnvDir = ".\\.pyenv"
$Script:PyEnvWinDir = "$PyEnvDir\\pyenv-win"
$Script:BinPath = "$PyEnvWinDir\\bin"
$Script:ShimsPath = "$PyEnvWinDir\\shims"
$Script:EnvScript = ".\pyenv-env.ps1"
$Script:ActivationScript = ".\activate-python.ps1"

# 颜色定义
$Script:SuccessColor = "Green"
$Script:WarningColor = "Yellow"
$Script:ErrorColor = "Red"
$Script:InfoColor = "Cyan"
$Script:HighlightColor = "Magenta"

# 区域：工具函数
#-----------------------------------------------------------
Function Write-Status {
    param(
        [string]$Message,
        [string]$Status = "INFO",
        [string]$Color = $InfoColor,
        [switch]$NoNewline
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $statusText = switch ($Status) {
        "SUCCESS" { "[✓]" }
        "WARNING" { "[!]" }
        "ERROR"   { "[✗]" }
        "DEBUG"   { "[D]" }
        default   { "[i]" }
    }
    
    $output = "$timestamp $statusText $Message"
    if ($NoNewline) {
        Write-Host $output -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $output -ForegroundColor $Color
    }
}

Function Test-CommandAvailable {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

Function Test-PyEnvInstalled {
    return (Test-Path "$PyEnvWinDir\\bin\\pyenv.bat") -and (Test-Path $PyEnvWinDir)
}

Function Test-PyEnvEnvironment {
    if (-not $env:PYENV) {
        Write-Status "PYENV 环境变量未设置" "WARNING" $WarningColor
        return $false
    }
    
    if (-not (Test-CommandAvailable "pyenv")) {
        Write-Status "pyenv 命令未在 PATH 中找到" "WARNING" $WarningColor
        return $false
    }
    
    return $true
}

Function Ensure-PyEnvEnvironment {
    if (-not (Test-PyEnvEnvironment)) {
        Write-Status "尝试自动配置环境..." "INFO" $InfoColor
        Configure-Environment | Out-Null
        
        if (-not (Test-PyEnvEnvironment)) {
            Write-Status "自动配置失败，请手动运行 .\$EnvScript" "ERROR" $ErrorColor
            return $false
        }
    }
    return $true
}

# 区域：核心功能
#-----------------------------------------------------------
Function Install-PyEnv {
    if (Test-PyEnvInstalled) {
        Write-Status "pyenv-win 已安装" "INFO" $InfoColor
        return $true
    }

    # 创建安装目录
    New-Item -Path $PyEnvDir -ItemType Directory -Force | Out-Null

    # 下载并解压
    $zipPath = "$PyEnvDir\\pyenv-win.zip"
    try {
        Write-Status "正在下载 pyenv-win..." "INFO" $InfoColor
        Invoke-WebRequest "https://github.com/pyenv-win/pyenv-win/archive/master.zip" -OutFile $zipPath -UserAgent "Pyenv-Install-Script"
        
        Write-Status "正在解压文件..." "INFO" $InfoColor
        Expand-Archive -Path $zipPath -DestinationPath $PyEnvDir -Force
        Move-Item "$PyEnvDir\\pyenv-win-master\\*" $PyEnvDir -Force -ErrorAction Stop
        Remove-Item "$PyEnvDir\\pyenv-win-master" -Recurse -Force -ErrorAction SilentlyContinue
        
        # 验证安装
        if (-not (Test-Path "$PyEnvWinDir\\bin\\pyenv.bat")) {
            throw "安装后未找到 pyenv.bat 文件"
        }
        
        Write-Status "pyenv-win 安装成功" "SUCCESS" $SuccessColor
        return $true
    }
    catch {
        Write-Status "安装过程中出错: $($_.Exception.Message)" "ERROR" $ErrorColor
        Write-Status "详细信息: $($_.InvocationInfo.PositionMessage)" "DEBUG" $InfoColor
        return $false
    }
    finally {
        if (Test-Path $zipPath) { 
            Remove-Item $zipPath -Force -ErrorAction SilentlyContinue 
        }
    }
}

Function Generate-EnvScript {
    try {
        $pyenvWinFullPath = (Resolve-Path $PyEnvWinDir -ErrorAction SilentlyContinue).Path
        if (-not $pyenvWinFullPath) {
            $pyenvWinFullPath = (Join-Path $PWD.Path $PyEnvWinDir.Replace(".\\", ""))
        }
        
        $binFullPath = Join-Path $pyenvWinFullPath "bin"
        $shimsFullPath = Join-Path $pyenvWinFullPath "shims"
        
        $envScriptContent = @"
<#
.SYNOPSIS
配置 pyenv-win 环境变量

.DESCRIPTION
为当前 PowerShell 会话设置临时环境变量
使用前请先运行此脚本

.EXAMPLE
. .\pyenv-env.ps1
#>

# 清除已有的 pyenv 路径
`$oldPath = [System.Environment]::GetEnvironmentVariable('PATH', 'Process')
`$pathParts = `$oldPath -split ';' | Where-Object {
    `$_ -notmatch 'pyenv-win\\bin' -and `$_ -notmatch 'pyenv-win\\shims'
}
`$newPath = `$pathParts -join ';'

# 设置 pyenv 环境变量
`$env:PYENV = "$pyenvWinFullPath\\"
`$env:PYENV_ROOT = "$pyenvWinFullPath\\"
`$env:PYENV_HOME = "$pyenvWinFullPath\\"

# 添加 pyenv 路径到 PATH 开头
`$env:PATH = "$binFullPath;$shimsFullPath;`$newPath"

Write-Host "[环境] pyenv-win 环境变量已配置" -ForegroundColor Green
"@

        Set-Content -Path $EnvScript -Value $envScriptContent -Encoding UTF8
        Write-Status "环境脚本已创建: $EnvScript" "SUCCESS" $SuccessColor
        return $true
    }
    catch {
        Write-Status "创建环境脚本失败: $($_.Exception.Message)" "ERROR" $ErrorColor
        return $false
    }
}

Function Generate-ActivationScript {
    param(
        [string]$PythonVersion = ""
    )
    
    try {
        $scriptContent = @"
<#
.SYNOPSIS
激活 Python 环境

.DESCRIPTION
配置 pyenv 环境并设置指定的 Python 版本
适用于当前 PowerShell 会话

.PARAMETER Version
要激活的 Python 版本 (可选)

.EXAMPLE
# 激活环境但不指定 Python 版本
. .\activate-python.ps1

# 激活环境并设置 Python 3.11.0
. .\activate-python.ps1 -Version 3.11.0
#>

param(
    [string]`$Version = ""
)

# 第一步：配置 pyenv 环境
if (Test-Path ".\$EnvScript") {
    . ".\$EnvScript"
    Write-Host "[环境] pyenv-win 环境已配置" -ForegroundColor Green
}
else {
    Write-Host "[错误] 未找到 $EnvScript" -ForegroundColor Red
    exit 1
}

# 第二步：设置指定的 Python 版本
if (`$Version -ne "") {
    pyenv local `$Version
    if (`$?) {
        Write-Host "[环境] Python 版本设置为: `$Version" -ForegroundColor Green
        
        # 验证 Python 版本
        `$actualVersion = python --version 2>&1 | Select-String -Pattern "Python (\d+\.\d+\.\d+)" | ForEach-Object { `$_.Matches.Groups[1].Value }
        
        if (`$actualVersion -ne `$Version) {
            Write-Host "[警告] 设置的版本 (`$Version) 与实际的版本 (`$actualVersion) 不一致" -ForegroundColor Yellow
        }
        else {
            Write-Host "[成功] Python 版本验证通过: `$actualVersion" -ForegroundColor Green
        }
    }
    else {
        Write-Host "[错误] 设置 Python 版本失败: `$Version" -ForegroundColor Red
    }
}

# 显示当前环境信息
Write-Host "`n当前 Python 环境信息:" -ForegroundColor Cyan
Write-Host "pyenv 版本: $(pyenv --version)"
Write-Host "Python 版本: $(python --version 2>&1 | Select-String -Pattern 'Python \d+\.\d+\.\d+')"
Write-Host "Python 路径: $(Get-Command python | Select-Object -ExpandProperty Source)`n"
"@

        Set-Content -Path $ActivationScript -Value $scriptContent -Encoding UTF8
        Write-Status "环境激活脚本已创建: $ActivationScript" "SUCCESS" $SuccessColor
        return $true
    }
    catch {
        Write-Status "创建激活脚本失败: $($_.Exception.Message)" "ERROR" $ErrorColor
        return $false
    }
}

Function Configure-Environment {
    if (-not (Test-Path $EnvScript)) {
        Write-Status "环境脚本不存在，正在创建..." "WARNING" $WarningColor
        if (-not (Generate-EnvScript)) {
            return $false
        }
    }
    
    try {
        . $EnvScript
        if (Test-PyEnvEnvironment) {
            Write-Status "环境配置成功" "SUCCESS" $SuccessColor
            return $true
        }
        return $false
    }
    catch {
        Write-Status "配置环境时出错: $($_.Exception.Message)" "ERROR" $ErrorColor
        return $false
    }
}

Function Show-AvailableVersions {
    if (-not (Ensure-PyEnvEnvironment)) {
        return $false
    }
    
    try {
        Write-Status "正在获取可安装版本列表..." "INFO" $InfoColor -NoNewline
        
        # 获取版本列表并缓存
        $cacheFile = "$env:TEMP\\pyenv_versions_$(Get-Date -Format 'yyyyMMdd').txt"
        
        if (-not (Test-Path $cacheFile) ){
            pyenv install --list | Out-File $cacheFile -Encoding UTF8
        }
        
        $versions = Get-Content $cacheFile | 
            Where-Object { $_ -match '^\s*\d+\.\d+\.\d+\s*$' } | 
            ForEach-Object { $_.Trim() } | 
            Sort-Object { [version]$_ } -Descending
        
        Write-Host " 完成" -ForegroundColor $SuccessColor
        
        # 分页显示
        $page = 1
        $pageSize = 20
        $totalPages = [math]::Ceiling($versions.Count / $pageSize)
        
        while ($true) {
            $startIndex = ($page - 1) * $pageSize
            $endIndex = [math]::Min($startIndex + $pageSize - 1, $versions.Count - 1)
            $displayVersions = $versions[$startIndex..$endIndex]
            
            Clear-Host
            Write-Host "`n可安装的 Python 版本 (第 $page/$totalPages 页)" -ForegroundColor $HighlightColor
            Write-Host "=" * 70
            
            # 分组显示
            $majorGroups = $displayVersions | Group-Object { $_.Split('.')[0] }
            
            foreach ($group in $majorGroups) {
                Write-Host "`nPython $($group.Name).x 系列:" -ForegroundColor $InfoColor
                $group.Group -join "  "
            }
            
            Write-Host "`n" + ("=" * 70)
            Write-Host "导航: N-下一页, P-上一页, F-首页, L-末页, S-搜索, Q-退出"
            
            # 用户输入
            $choice = Read-Host "`n选择操作"
            
            switch ($choice.ToUpper()) {
                "N" { if ($page -lt $totalPages) { $page++ } }
                "P" { if ($page -gt 1) { $page-- } }
                "F" { $page = 1 }
                "L" { $page = $totalPages }
                "S" {
                    $searchTerm = Read-Host "输入搜索关键字 (例如: 3.11)"
                    $searchResults = $versions | Where-Object { $_ -like "*$searchTerm*" }
                    
                    if ($searchResults) {
                        Clear-Host
                        Write-Host "`n搜索结果 (包含 '$searchTerm'):" -ForegroundColor $HighlightColor
                        Write-Host "=" * 70
                        $searchResults -join "  "
                        Write-Host "`n" + ("=" * 70)
                        Pause
                    }
                    else {
                        Write-Status "未找到匹配的版本" "WARNING" $WarningColor
                        Start-Sleep -Seconds 2
                    }
                }
                "Q" { return $true }
                default {
                    # 尝试作为版本号处理
                    if ($choice -match '^\d+\.\d+\.\d+$') {
                        if ($versions -contains $choice) {
                            $installChoice = Read-Host "是否安装 $choice? (y/n)"
                            if ($installChoice -eq 'y') {
                                Install-PythonVersion -Version $choice
                                Pause
                            }
                        }
                        else {
                            Write-Status "$choice 不是有效的版本号" "WARNING" $WarningColor
                            Start-Sleep -Seconds 2
                        }
                    }
                }
            }
        }
        
        return $true
    }
    catch {
        Write-Status "获取版本列表失败: $($_.Exception.Message)" "ERROR" $ErrorColor
        return $false
    }
}

Function Install-PythonVersion {
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^\d+\.\d+\.\d+$')]
        [string]$Version
    )
    
    if (-not (Test-PyEnvInstalled)) {
        Write-Status "pyenv-win 未安装，请先安装" "ERROR" $ErrorColor
        return $false
    }
    
    if (-not (Ensure-PyEnvEnvironment)) {
        return $false
    }
    
    try {
        Write-Status "正在安装 Python $Version..." "INFO" $InfoColor
        pyenv install $Version
        
        if ($LASTEXITCODE -eq 0) {
            Write-Status "Python $Version 安装成功" "SUCCESS" $SuccessColor
            
            # 生成激活脚本
            Generate-ActivationScript -PythonVersion $Version
            
            return $true
        }
        
        Write-Status "安装失败 (退出代码: $LASTEXITCODE)" "ERROR" $ErrorColor
        return $false
    }
    catch {
        Write-Status "安装 Python $Version 失败: $($_.Exception.Message)" "ERROR" $ErrorColor
        return $false
    }
}

Function Set-LocalPythonVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )
    
    if (-not (Ensure-PyEnvEnvironment)) {
        return $false
    }
    
    try {
        # 验证版本是否存在
        $installedVersions = pyenv versions --bare
        if (-not ($installedVersions -contains $Version)) {
            Write-Status "Python $Version 未安装" "WARNING" $WarningColor
            
            $installChoice = Read-Host "是否安装 $Version? (y/n)"
            if ($installChoice -eq 'y') {
                Install-PythonVersion -Version $Version
            }
            else {
                return $false
            }
        }
        
        # 设置版本
        pyenv local $Version
        if ($LASTEXITCODE -eq 0) {
            Write-Status "当前目录已设置为 Python $Version" "SUCCESS" $SuccessColor
            
            # 生成激活脚本
            Generate-ActivationScript -PythonVersion $Version
            
            return $true
        }
        
        Write-Status "设置失败 (退出代码: $LASTEXITCODE)" "ERROR" $ErrorColor
        return $false
    }
    catch {
        Write-Status "设置本地 Python 版本失败: $($_.Exception.Message)" "ERROR" $ErrorColor
        return $false
    }
}

Function Show-InstalledVersions {
    if (-not (Ensure-PyEnvEnvironment)) {
        return $false
    }
    
    try {
        Write-Host "`n已安装的 Python 版本:" -ForegroundColor $HighlightColor
        Write-Host "=" * 50
        
        $globalVersion = pyenv global
        $localVersion = pyenv local
        
        pyenv versions | ForEach-Object {
            if ($_ -match "\* (.+?)\s") {
                $version = $matches[1]
                
                if ($version -eq $globalVersion) {
                    Write-Host $_ -ForegroundColor $SuccessColor
                }
                elseif ($version -eq $localVersion) {
                    Write-Host $_ -ForegroundColor $InfoColor
                }
                else {
                    Write-Host $_
                }
            }
            else {
                Write-Host $_
            }
        }
        
        Write-Host "`n全局版本: $globalVersion"
        Write-Host "本地版本: $localVersion"
        Write-Host "=" * 50
        
        return $true
    }
    catch {
        Write-Status "获取已安装版本失败: $($_.Exception.Message)" "ERROR" $ErrorColor
        return $false
    }
}

Function Uninstall-PyEnv {
    if (-not (Test-PyEnvInstalled)) {
        Write-Status "pyenv-win 未安装" "INFO" $InfoColor
        return $true
    }
    
    try {
        # 获取确认
        $confirm = Read-Host "`n确定要卸载 pyenv-win 吗? 这将删除所有安装的Python版本 (y/n)"
        if ($confirm -ne "y") {
            return $false
        }
        
        # 删除目录
        Remove-Item -Path $PyEnvDir -Recurse -Force -ErrorAction Stop
        
        # 删除脚本文件
        if (Test-Path $EnvScript) {
            Remove-Item -Path $EnvScript -Force -ErrorAction SilentlyContinue
        }
        
        if (Test-Path $ActivationScript) {
            Remove-Item -Path $ActivationScript -Force -ErrorAction SilentlyContinue
        }
        
        Write-Status "pyenv-win 卸载成功" "SUCCESS" $SuccessColor
        return $true
    }
    catch {
        Write-Status "卸载失败: $($_.Exception.Message)" "ERROR" $ErrorColor
        return $false
    }
}

# 区域：用户界面
#-----------------------------------------------------------
Function Show-Menu {
    Clear-Host
    Write-Host "`n" * 3
    Write-Host "PYENV-WIN 高级管理工具" -ForegroundColor $HighlightColor
    Write-Host "=" * 70
    Write-Host "1. 安装/更新 pyenv-win" -ForegroundColor $InfoColor
    Write-Host "2. 配置当前会话环境变量" -ForegroundColor $InfoColor
    Write-Host "3. 显示所有可安装的 Python 版本" -ForegroundColor $InfoColor
    Write-Host "4. 安装 Python 版本" -ForegroundColor $InfoColor
    Write-Host "5. 设置当前目录的 Python 版本" -ForegroundColor $InfoColor
    Write-Host "6. 显示已安装的 Python 版本" -ForegroundColor $InfoColor
    Write-Host "7. 生成环境激活脚本" -ForegroundColor $InfoColor
    Write-Host "8. 卸载 pyenv-win" -ForegroundColor $InfoColor
    Write-Host "0. 退出" -ForegroundColor $InfoColor
    Write-Host "=" * 70
    
    # 显示当前状态
    if (Test-PyEnvInstalled) {
        Write-Host "状态: pyenv-win 已安装" -ForegroundColor $SuccessColor
    } else {
        Write-Host "状态: pyenv-win 未安装" -ForegroundColor $WarningColor
    }
    
    if (Test-PyEnvEnvironment) {
        $pyenvVersion = pyenv --version 2>&1 | Select-String -Pattern "pyenv \d+\.\d+\.\d+"
        if ($pyenvVersion -and $pyenvVersion.Matches -and $pyenvVersion.Matches.Count -gt 0) {
            Write-Host "环境: 已配置 ($($pyenvVersion.Matches[0].Value))" -ForegroundColor $SuccessColor
        } else {
            Write-Host "环境: 已配置 (版本未知)" -ForegroundColor $SuccessColor
        }
    } else {
        Write-Host "环境: 未配置" -ForegroundColor $WarningColor
    }
    
    if (Test-Path $ActivationScript) {
        Write-Host "激活脚本: 已生成 ($ActivationScript)" -ForegroundColor $SuccessColor
    } else {
        Write-Host "激活脚本: 未生成" -ForegroundColor $InfoColor
    }
}

Function Pause {
    Write-Host "`n按 Enter 键继续..."
    $null = Read-Host
}

# 区域：主程序逻辑
#-----------------------------------------------------------
Function Main {
    # 参数处理
    switch ($PSCmdlet.ParameterSetName) {
        'SilentInstall' {
            if (Install-PyEnv) {
                Configure-Environment | Out-Null
                Install-PythonVersion -Version $InstallPython
            }
            exit
        }
        
        'GenerateScript' {
            if (-not (Test-PyEnvInstalled)) {
                Write-Status "pyenv-win 未安装，请先安装" "ERROR" $ErrorColor
                exit 1
            }
            
            Generate-ActivationScript
            exit
        }
        
        'SetVersion' {
            if (-not (Test-PyEnvInstalled)) {
                Write-Status "pyenv-win 未安装，请先安装" "ERROR" $ErrorColor
                exit 1
            }
            
            Configure-Environment | Out-Null
            Set-LocalPythonVersion -Version $SetLocalVersion
            exit
        }
    }
    
    # 交互式菜单模式
    while ($true) {
        Show-Menu
        $choice = Read-Host "`n请选择操作 (0-8)"
        
        switch ($choice) {
            "1" {
                if (Install-PyEnv) {
                    Generate-EnvScript
                    Configure-Environment
                }
                Pause
            }
            "2" {
                Configure-Environment
                Pause
            }
            "3" {
                Show-AvailableVersions
            }
            "4" {
                $version = Read-Host "`n请输入要安装的 Python 版本 (例如: 3.11.0)"
                if ($version -ne "") {
                    Install-PythonVersion -Version $version
                }
                Pause
            }
            "5" {
                $version = Read-Host "`n请输入要设置的 Python 版本 (例如: 3.11.0)"
                if ($version -ne "") {
                    Set-LocalPythonVersion -Version $version
                }
                Pause
            }
            "6" {
                Show-InstalledVersions
                Pause
            }
            "7" {
                $version = Read-Host "`n请输入要激活的 Python 版本 (可选，直接回车跳过)"
                Generate-ActivationScript -PythonVersion $version
                Pause
            }
            "8" {
                Uninstall-PyEnv
                Pause
            }
            "0" {
                Write-Status "退出" "INFO" $InfoColor
                exit
            }
            default {
                Write-Status "无效选择，请重新输入" "ERROR" $ErrorColor
                Start-Sleep -Seconds 2
            }
        }
    }
}

# 入口点
try {
    Main
}
catch {
    Write-Status "未处理的异常: $($_.Exception.Message)" "ERROR" $ErrorColor
    Write-Status "堆栈跟踪: $($_.ScriptStackTrace)" "DEBUG" $InfoColor
    exit 1
}