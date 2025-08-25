# AnythingLLM MCP 服务器 (SSE模式)

## 概述

这个目录包含了一个基于FastMCP框架实现的AnythingLLM集成服务器，使用Server-Sent Events (SSE) 作为传输方式。该服务器提供了与AnythingLLM交互的各种功能，包括查询、文件上传、工作区管理等。

## 文件结构

```
AnythingLLM_MCP/sse/
└── anythingllmmcp/
    ├── .env             # 环境变量配置文件
    ├── client.py        # 测试客户端
    ├── run.cmd          # Windows启动脚本
    ├── server.py        # 基础版服务器
    └── server_v2.py     # 完整版服务器
```

## 功能特点

### 基础功能 (server.py)
- 基于FastMCP框架构建
- 支持SSE传输方式
- 提供查询AnythingLLM的功能
- 环境变量配置支持

### 高级功能 (server_v2.py)
- 完整的工作区管理 (创建、列出工作区)
- 文件上传功能 (支持单个文件和整个文件夹)
- 增强的错误处理和重试机制
- 支持多种文件类型的MIME类型映射
- 内部辅助函数封装

## 环境变量配置

在`.env`文件中配置以下变量：

```
ANYTHINGLLM_API_KEY=your_api_key
ANYTHINGLLM_BASE_URL=http://localhost:3001
WORKSPACE_NAME=my
```

## 使用方法

### 启动服务器

1. 确保已安装所需依赖：
   ```
   pip install fastmcp httpx python-dotenv
   ```

2. 在Windows上运行：
   ```
   双击 run.cmd 文件
   ```

3. 或者通过命令行运行：
   ```
   python server_v2.py
   ```

### 测试服务器

运行客户端测试脚本：
```
python client.py
```

## API 功能

服务器提供以下工具：

1. `list_workspaces`: 列出所有工作区
2. `create_workspace`: 创建新工作区
3. `upload_file`: 上传单个文件
4. `upload_folder`: 上传整个文件夹
5. `query`: 向工作区提问

## 代码示例

### 查询工作区

```python
async with Client("http://localhost:8203/sse") as client:
    result = await client.call_tool("list_workspaces", {})
    print(result)
```

### 上传文件

```python
async with Client("http://localhost:8203/sse") as client:
    result = await client.call_tool("upload_file", {
        "workspace": "my_workspace",
        "file_path": "/path/to/file.txt"
    })
    print(result)
```

## 注意事项

1. 确保AnythingLLM服务器正在运行，并且API密钥有效。
2. 服务器默认运行在端口8003 (server.py) 或8203 (server_v2.py)。
3. 对于大型文件或文件夹的上传，可能需要调整超时设置。
4. 开发环境使用Python 3.10+。