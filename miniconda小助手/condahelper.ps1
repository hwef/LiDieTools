#Requires -Version 5.1
<#
.SYNOPSIS
Conda环境管理工具 - 提供安全的交互式conda环境管理功能
#>

function Show-CondaEnvs {
    <#
    .DESCRIPTION
    显示所有已创建的conda环境，包含名称和完整路径
    #>
    $envs = conda env list --json | ConvertFrom-Json
    $results = @()
    
    # 解析基础环境
    if ($envs.root_prefix) {
        $results += [PSCustomObject]@{
            Index = 0
            Name = "base"
            Path = $envs.root_prefix
        }
    }

    # 解析其他环境
    $index = 1
    foreach ($envPath in $envs.envs) {
        # 排除基础环境重复显示
        if ($envPath -ne $envs.root_prefix) {
            # 提取环境名称（路径的最后一段）
            $envName = Split-Path $envPath -Leaf
            $results += [PSCustomObject]@{
                Index = $index
                Name = $envName
                Path = $envPath
            }
            $index++
        }
    }
    
    return $results
}
function Get-CondaEnvScript {
    param(
        [Parameter(Mandatory=$true)]
        [string]$EnvPath
    )
    <#
    .DESCRIPTION
    生成指定conda环境的环境变量设置脚本（仅影响当前终端会话）
    #>
    $scriptContent = @"
# CONDITIONAL ENVIRONMENT VARIABLES SCRIPT
# Generated at: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# Environment path: $EnvPath
# Note: Only affects current terminal session

# Define private environment variables (session-scoped)
# 定义仅在当前会话中有效的环境变量
`$private:condaPrefix = "$EnvPath"
`$private:envName = "$(Split-Path $EnvPath -Leaf)"

# Create functions for environment interaction
# 创建用于环境交互的函数
function Get-CondaEnvironment {
    `$env:CONDA_PREFIX = `$private:condaPrefix
    `$env:CONDA_DEFAULT_ENV = `$private:envName
    `$env:PATH = "`$private:condaPrefix;`$private:condaPrefix\Library\bin;`$private:condaPrefix\Scripts;`$private:condaPrefix\bin;" + `$env:PATH
    Write-Host "`n[SUCCESS] Activated environment: `$private:envName" -ForegroundColor Green
}

function ResetCondaEnvironment {
    # Reset to system environment (remove private variables)
    # 重置为系统环境（清除私有变量）
    `$env:CONDA_PREFIX = `$null
    `$env:CONDA_DEFAULT_ENV = `$null
    
    # Remove conda paths from session PATH
    # 从会话PATH中移除conda路径
    `$newPath = (`$env:PATH -split ';' | Where-Object {
        `$_ -notlike "*`$private:condaPrefix*"
    }) -join ';'
    `$env:PATH = `$newPath
    
    # Clear private variables
    # 清除私有变量
    Remove-Variable -Scope Private -Name condaPrefix, envName -ErrorAction Ignore
    
    Write-Host "`n[INFO] Conda environment variables reset" -ForegroundColor Green
}

# Usage instructions
# 使用说明
Write-Host "`nEnvironment script loaded for: `$private:envName" -ForegroundColor Cyan
Write-Host "Use 'Get-CondaEnvironment' to activate in this terminal" -ForegroundColor Yellow
Write-Host "Use 'ResetCondaEnvironment' to deactivate" -ForegroundColor Yellow
"@

    return $scriptContent
}
function Invoke-ActivateEnv {
    param(
        [Parameter(Mandatory=$true)]
        [string]$EnvPath
    )
    <#
    .DESCRIPTION
    使用指定路径激活conda环境，生成临时环境变量脚本
    #>
    $activationScript = @"
# TEMPORARY CONDA ACTIVATION SCRIPT (Expires on shell exit)
`$env:PATH = "$EnvPath;$EnvPath\Library\bin;$EnvPath\Scripts;$EnvPath\bin;`$env:PATH"
`$env:CONDA_PREFIX = "$EnvPath"
Write-Host "[INFO] 已激活环境: $EnvPath" -ForegroundColor Green
"@

    # 创建临时脚本（仅内存）
    $tempScript = [System.IO.Path]::GetTempFileName() + ".ps1"
    $activationScript | Out-File -FilePath $tempScript -Encoding utf8
    
    # 执行临时脚本
    . $tempScript
    Remove-Item $tempScript -Force
    
    # 设置仅当前会话可见的环境变量
    $env:CONDA_ACTIVATED = "1"
    $env:CONDA_CURRENT_ENV_PATH = $EnvPath
}

function Invoke-UserPause {
    <#
    .DESCRIPTION
    安全暂停机制 - 等待用户按键继续
    #>
    Write-Host "`n[安全机制] 操作完成，按任意键继续..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

function Get-ValidatedInput {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,
        [ValidateSet('int','path')]
        [string]$Type = 'int'
    )
    
    do {
        $input = Read-Host $Prompt
        if ([string]::IsNullOrWhiteSpace($input)) {
            Write-Host "输入不能为空" -ForegroundColor Red
            continue
        }
        
        switch ($Type) {
            'int' {
                if ($input -match '^\d+$') { return [int]$input }
                Write-Host "请输入有效数字" -ForegroundColor Red
            }
            'path' {
                if (Test-Path $input) { return $input }
                Write-Host "路径不存在，请重新输入" -ForegroundColor Red
            }
        }
    } while ($true)
}

# 主程序
try {
    # 安全性检查
    if (-not (Get-Command conda -ErrorAction SilentlyContinue)) {
        throw "未找到conda命令！请确认Anaconda/Miniconda已安装并配置"
    }

    while ($true) {
        Clear-Host
        Write-Host @"
        
██████  ██████  ███    ██ ██████  ███████ 
██   ██ ██   ██ ████   ██ ██   ██ ██      
██████  ██   ██ ██ ██  ██ ██   ██ █████  
██      ██   ██ ██  ██ ██ ██   ██ ██      
██       █████  ██   ████ ██████  ███████ 
                                          
        安全版环境管理工具 v1.0
══════════════════════════════════════════
"@ -ForegroundColor Cyan

        # 显示所有环境
        $envs = Show-CondaEnvs
        Write-Host "`n可用环境列表:" -ForegroundColor Green
        $envs | Format-Table @{ 
            Label = "序号" 
            Expression = { $_.Index } 
            Width = 6 
        }, 
        @{ 
            Label = "环境名称" 
            Expression = { $_.Name } 
            Width = 15 
        }, 
        @{ 
            Label = "完整路径" 
            Expression = { $_.Path } 
        } -AutoSize

        # 显示操作菜单
        Write-Host @"

══════════════════════════════════════════
1. 激活环境 (按序号)        
2. 创建新环境               
3. 通过路径激活             
4. 生成变量设置脚本(保存在当前文件夹下)    
5. 删除环境
6. 克隆环境
# 7. 导出环境变量脚本(暂停使用)
8. 退出程序
══════════════════════════════════════════
"@ -ForegroundColor DarkCyan

        # 获取用户选择
        $choice = Get-ValidatedInput -Prompt "请选择操作 (1-8)" -Type 'int'
        
        try {
            switch ($choice) {
                1 { # 按序号激活
                    $envIndex = Get-ValidatedInput -Prompt "请输入环境序号" -Type 'int'
                    $selectedEnv = $envs | Where-Object { $_.Index -eq $envIndex }
                    if ($selectedEnv) {
                        Invoke-ActivateEnv -EnvPath $selectedEnv.Path
                    } else {
                        Write-Host "`n[错误] 无效的环境序号" -ForegroundColor Red
                    }
                }
                
                2 {
    $envName = Read-Host "输入新环境名称"
    $pythonVersion = Read-Host "输入Python版本 (例如 3.9)"
    
    # 询问用户是否在默认位置创建
    $choice = Read-Host "是否在 Conda 默认位置创建? (y/n) [默认 n]"
    
    if ($choice -eq 'y') {
        # 用户要求使用Conda默认位置
        conda create --name $envName python=$pythonVersion -y
        Write-Host "环境 '$envName' 已创建在 Conda 默认位置"
    } else {
        # 默认行为 - 在当前目录的venv中创建
        $venvPath = Join-Path -Path $PWD -ChildPath "venv"
        
        # 确保venv目录存在
        if (-not (Test-Path -Path $venvPath)) {
            New-Item -ItemType Directory -Path $venvPath | Out-Null
            Write-Host "已创建 venv 目录: $venvPath"
        }
        
        $envPath = Join-Path -Path $venvPath -ChildPath $envName
        conda create --prefix "$envPath" python=$pythonVersion -y
        Write-Host "环境 '$envName' 已创建在: $envPath"
    }
}
                
                3 { # 按路径激活
                    $envPath = Get-ValidatedInput -Prompt "输入完整环境路径" -Type 'path'
                    Invoke-ActivateEnv -EnvPath $envPath
                }
               4 { # 新增：生成变量设置脚本
    $envIndex = Get-ValidatedInput -Prompt "请输入环境序号" -Type 'int'
    $selectedEnv = $envs | Where-Object { $_.Index -eq $envIndex }
    
    if ($selectedEnv) {
        $script = Get-CondaEnvScript -EnvPath $selectedEnv.Path
        
        # 在当前目录创建脚本文件
        $scriptPath = Join-Path -Path $PWD.Path -ChildPath "set_env_path.ps1"
        $script | Out-File -FilePath $scriptPath -Encoding utf8
        
        # 检查是否创建成功
        if (Test-Path $scriptPath) {
            Write-Host @"
`n[成功] 环境变量脚本已创建在当前目录
文件名: set_env_path.ps1
使用方法:
1. 在当前终端激活: . .\set_env_path.ps1
2. 恢复原始环境: Reset-CondaEnvironment
3. 该设置仅对当前终端有效
注意：每次运行此选项会覆盖旧脚本
"@ -ForegroundColor Green
        } else {
            Write-Host "`n[错误] 文件创建失败: $scriptPath" -ForegroundColor Red
        }
    } else {
        Write-Host "`n[错误] 无效的环境序号" -ForegroundColor Red
    }
}
              5 { # 删除环境
    $envIndex = Get-ValidatedInput -Prompt "输入要删除的环境序号" -Type 'int'
    $target = $envs | Where-Object { $_.Index -eq $envIndex }
    if ($target) {
        # 检查是否为base环境
        if ($target.Name -eq 'base') {
            Write-Host "`n[错误] 不能删除 base 环境" -ForegroundColor Red
        } else {
            # 使用路径删除
            conda remove --prefix "$($target.Path)" --all -y
            Write-Host "环境 $($target.Name) 已删除"
        }
    } else {
        Write-Host "`n[错误] 无效的环境序号" -ForegroundColor Red
    }
}
                
              
                
                6 { # 克隆环境
                    $sourceIndex = Get-ValidatedInput -Prompt "输入要克隆的环境序号" -Type 'int'
                    $newName = Read-Host "输入新环境名称"
                    $source = $envs | Where-Object { $_.Index -eq $sourceIndex }
                    if ($source) {
                        conda create --name $newName --clone $source.Name -y
                    } else {
                        Write-Host "`n[错误] 无效的源环境序号" -ForegroundColor Red
                    }
                }
                # 7 { # 导出环境变量脚本
                #     $envIndex = Get-ValidatedInput -Prompt "请输入环境序号" -Type 'int'
                #     $outputFile = Read-Host "输入保存脚本的完整路径（例如：C:\env_script.ps1）"
                #     $selectedEnv = $envs | Where-Object { $_.Index -eq $envIndex }
                    
                #     if ($selectedEnv) {
                #         $script = Get-CondaEnvScript -EnvPath $selectedEnv.Path
                #         $script | Out-File -FilePath $outputFile -Encoding utf8
                #         Write-Host "`n[成功] 环境变量脚本已导出至: $outputFile" -ForegroundColor Green
                #     } else {
                #         Write-Host "`n[错误] 无效的环境序号" -ForegroundColor Red
                #     }
                # }
                
                8 { # 退出（原5更新为8）
                    Write-Host "`n[安全退出] 感谢使用环境管理工具" -ForegroundColor Green
                    exit 0
                }
                default {
                    Write-Host "`n[错误] 无效的选择" -ForegroundColor Red
                }
            }
        } catch {
            Write-Host "`n[错误] 操作失败: $_" -ForegroundColor Red
        } finally {
            # 强制用户交互暂停
            Invoke-UserPause
        }
    }
} catch {
    Write-Host "`n[致命错误] $($_.Exception.Message)" -ForegroundColor Red
    Invoke-UserPause
    exit 1
}