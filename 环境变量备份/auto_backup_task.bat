@echo off
setlocal
chcp 65001
:: 创建备份目录
mkdir "C:\EnvVarBackup" >nul 2>&1

:: 检查是否以管理员身份运行
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 请右键选择"以管理员身份运行"此脚本
    pause
    exit /b 1
)

:: 创建计划任务
schtasks /create /tn "EnvVarBackup" /tr "C:\EnvVarBackup\BackupEnvVars.bat" /sc hourly /mo 3 /ru SYSTEM /rl HIGHEST /f

if %errorLevel% equ 0 (
    echo 计划任务创建成功！每3小时自动备份环境变量
    echo 备份目录: C:\EnvVarBackup
    echo 日志文件: C:\EnvVarBackup\backup_log.txt
) else (
    echo 计划任务创建失败，错误代码: %errorLevel%
)

timeout /t 5 >nul
endlocal