@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

:: 检查是否以管理员权限运行
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo 请右键以管理员身份运行此脚本！
    pause
    exit /b 1
)

echo.
echo ==============================
echo  Conda & Pip 镜像加速配置工具
echo ==============================
echo 1) 清华大学镜像源（推荐）
echo 2) 中科大镜像源
echo 3) 阿里云镜像源
echo 4) 还原默认源
echo 5) 清理缓存
echo ==============================
choice /c 12345 /n /m "请选择操作: "

:: 镜像源定义
set TUNA=https://mirrors.tuna.tsinghua.edu.cn
set USTC=https://mirrors.ustc.edu.cn
set ALIYUN=https://mirrors.aliyun.com

:: 根据选择配置源
if %errorlevel% equ 1 (
    set conda_source=!TUNA!
    set pip_source=!TUNA!/pypi/simple
    set source_name=清华大学
) else if %errorlevel% equ 2 (
    set conda_source=!USTC!
    set pip_source=!USTC!/anaconda/pypi/simple
    set source_name=中国科技大学
) else if %errorlevel% equ 3 (
    set conda_source=!ALIYUN!
    set pip_source=!ALIYUN!/pypi/simple
    set source_name=阿里云
)

:: 执行操作
if %errorlevel% lss 4 (
    call :CONFIG_CONDA
    call :CONFIG_PIP
    call :CLEAN_CACHE
    echo.
    echo √ 已配置 !source_name! 镜像源
    echo    Conda源: !conda_source!
    echo    Pip源:   !pip_source!
) else if %errorlevel% equ 4 (
    call :RESTORE_DEFAULT
    echo.
    echo √ 已还原默认源
) else if %errorlevel% equ 5 (
    call :CLEAN_CACHE
    echo.
    echo √ 已清理缓存
)

echo.
pause
exit /b

:CONFIG_CONDA
:: 备份原配置文件
if exist "%USERPROFILE%\.condarc" (
    copy "%USERPROFILE%\.condarc" "%USERPROFILE%\.condarc.bak_%date:~0,4%%date:~5,2%%date:~8,2%" > nul
)

:: 生成.condarc文件
(
echo channels:
echo   - defaults
echo show_channel_urls: true
echo default_channels:
echo   - !conda_source!/anaconda/pkgs/main
echo   - !conda_source!/anaconda/pkgs/r
echo   - !conda_source!/anaconda/pkgs/msys2
echo custom_channels:
echo   conda-forge: !conda_source!/anaconda/cloud
echo   pytorch: !conda_source!/anaconda/cloud
) > "%USERPROFILE%\.condarc"
exit /b

:CONFIG_PIP
:: 创建pip配置目录
if not exist "%APPDATA%\pip" mkdir "%APPDATA%\pip"

:: 备份原配置文件
if exist "%APPDATA%\pip\pip.ini" (
    copy "%APPDATA%\pip\pip.ini" "%APPDATA%\pip\pip.ini.bak_%date:~0,4%%date:~5,2%%date:~8,2%" > nul
)

:: 生成pip.ini文件
(
echo [global]
echo index-url = !pip_source!
echo trusted-host = !pip_source:~8,-7!
) > "%APPDATA%\pip\pip.ini"

:: 确保pip命令可用
python -m ensurepip --default-pip > nul 2>&1
exit /b

:RESTORE_DEFAULT
:: 恢复默认conda配置
(
echo channels:
echo   - defaults
) > "%USERPROFILE%\.condarc"

:: 删除pip配置文件
if exist "%APPDATA%\pip\pip.ini" del "%APPDATA%\pip\pip.ini"
exit /b

:CLEAN_CACHE
conda clean -y --all > nul 2>&1
python -m pip cache purge > nul 2>&1
exit /b