@echo off
chcp 65001
setlocal enabledelayedexpansion

:: 获取时间戳
set "timestamp=%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "timestamp=%timestamp: =0%"  // 解决空格问题

:: 创建备份目录
set "backupDir=C:\EnvVarBackup\EnvBackup_%timestamp%"
mkdir "%backupDir%" >nul 2>&1

if not exist "%backupDir%" (
    echo [%time%] 创建备份目录失败，请检查权限 >> "C:\EnvVarBackup\backup_log.txt"
    exit /b 1
)

:: 备份注册表项
reg export "HKEY_CURRENT_USER\Environment" "%backupDir%\UserEnvVars.reg" >nul
reg export "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "%backupDir%\SystemEnvVars.reg" >nul 2>&1

:: 记录日志
echo [%timestamp%] 环境变量备份完成 >> "C:\EnvVarBackup\backup_log.txt"

:: 保留最近5个备份
for /f "skip=5" %%d in ('dir /ad /b /o-d "C:\EnvVarBackup\EnvBackup_*" 2^>nul') do (
    rmdir /s /q "C:\EnvVarBackup\%%d"
)

endlocal