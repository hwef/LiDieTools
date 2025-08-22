# 问题 vscode 使用python虚拟环境 调试时显示 xx model 路径不存在

## 解决办法

### setp1
- 创建.vscode 文件夹
- 在.vscode 文件夹中创建 launch.json 文件
- 在 launch.json 文件中添加如下内容
    ```
    {
        "version": "0.2.0",
        "configurations": [
            {
                "name": "Python: Current File (Virtual Env)",
                "type": "python",
                "request": "launch",
                "program": "${file}",
                "console": "integratedTerminal",
                "justMyCode": true,
                "env": {
                    "PYTHONPATH": "${workspaceFolder};${workspaceFolder}/src;${workspaceFolder}/datagen"
                },
                "python": "${command:python.interpreterPath}"
            }
        ]
    }
    ```

### setp2
- 在 .vscode 文件夹中创建 settings.json 文件
- 在 settings.json 文件中添加如下内容
    ```json
    {
    "python.autoComplete.extraPaths": ["${workspaceFolder}"],
    "python.analysis.extraPaths": ["${workspaceFolder}"],
    "terminal.integrated.env.windows": {
        "PYTHONPATH": "${workspaceFolder};${env:PYTHONPATH}"
    },
    "python.envFile": "${workspaceFolder}/.env"
    }
    ```

### setp3
- 在根目录创建.env 文件
- 在.env 文件中添加如下内容
    ```env
    PYTHONPATH=D:\Codes\python\Hyperspectral-Image-Classification
    ```
## 验证
   ```python
    import sys, os
    print(f"Python Path: {sys.executable}")
    print(f"Virtual Env: {os.getenv('VIRTUAL_ENV')}")
    print("PYTHONPATH:")
    # 配置正确会输出 .env 文件中配置的路径
    for p in sys.path:
        print(f" - {p}")

   ```