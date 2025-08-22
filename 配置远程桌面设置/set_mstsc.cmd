@echo off
chcp 65001
setlocal enabledelayedexpansion

REM 检查管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 请求管理员权限...
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

echo 正在配置远程桌面设置...

REM 启用远程桌面连接
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul

REM 关闭网络级别身份验证
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 0 /f >nul

REM 启用Windows防火墙规则
netsh advfirewall firewall set rule group="远程桌面" new enable=yes >nul

echo 操作成功完成！
echo 已启用：允许远程连接
echo 已启用：仅允许网络级别身份验证(NLA)
echo 远程桌面服务将在30秒后自动重启...
timeout /t 30 >nul

REM 重启远程桌面服务
net stop TermService >nul
net start TermService >nul

echo 所有设置已生效！
pause