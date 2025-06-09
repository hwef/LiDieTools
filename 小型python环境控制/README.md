# PyEnv-Win 高级管理工具

一个功能强大的PowerShell脚本，用于简化pyenv-win的安装、配置和Python版本管理。通过交互式菜单界面，轻松管理多个Python版本，无需记忆复杂命令。

## 功能特点

- 🚀 一键安装/更新 pyenv-win
- ⚙️ 自动配置环境变量
- 📋 列出所有可安装的Python版本
- 📥 轻松安装指定Python版本
- 🔄 设置当前目录的Python版本
- 📊 查看已安装的Python版本
- 📝 生成环境激活脚本
- 🗑️ 卸载pyenv-win

## 安装说明

1. 确保您的系统允许运行PowerShell脚本：
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. 下载脚本文件到您的计算机

3. 在PowerShell中导航到脚本所在目录并运行：
   ```powershell
   .\2.ps1
   ```

## 使用方法

运行脚本后，将显示交互式菜单：

```
PYENV-WIN 高级管理工具
======================================================================
1. 安装/更新 pyenv-win
2. 配置当前会话环境变量
3. 显示所有可安装的 Python 版本
4. 安装 Python 版本
5. 设置当前目录的 Python 版本
6. 显示已安装的 Python 版本
7. 生成环境激活脚本
8. 卸载 pyenv-win
0. 退出
======================================================================
状态: pyenv-win 已安装
环境: 已配置 (pyenv x.x.x)
```

选择对应的数字执行相应操作。

## 菜单选项详解

### 1. 安装/更新 pyenv-win
安装或更新pyenv-win到最新版本。如果已安装，将检查并更新到最新版本。

### 2. 配置当前会话环境变量
为当前PowerShell会话配置必要的环境变量，使pyenv命令可用。

### 3. 显示所有可安装的 Python 版本
列出所有可通过pyenv-win安装的Python版本。

### 4. 安装 Python 版本
安装指定的Python版本。会提示您输入要安装的版本号。

### 5. 设置当前目录的 Python 版本
为当前目录设置特定的Python版本，创建`.python-version`文件。

### 6. 显示已安装的 Python 版本
列出所有已通过pyenv-win安装的Python版本。

### 7. 生成环境激活脚本
生成用于激活特定Python版本环境的脚本。

### 8. 卸载 pyenv-win
完全卸载pyenv-win及其配置。

### 0. 退出
退出脚本。

## 注意事项

- 脚本需要在PowerShell环境中运行
- 某些操作可能需要管理员权限
- 首次使用时，建议先安装pyenv-win并配置环境变量

## 贡献指南

欢迎提交问题报告和改进建议！如果您想贡献代码，请遵循以下步骤：

1. Fork 本仓库
2. 创建您的特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交您的更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 打开一个 Pull Request

## 许可证

本项目采用 MIT 许可证 - 详情请参阅 LICENSE 文件。