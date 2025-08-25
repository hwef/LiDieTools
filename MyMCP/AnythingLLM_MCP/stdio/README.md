# AnythingLLM MCP 工具

这个项目是将AnythingLLM与FastMCP集成的工具，用于实现RAG（检索增强生成）功能。

## 目录结构

```
AnythingLLM_MCP/
├── .env                      # 环境变量配置文件
├── anythingllm_client.py     # AnythingLLM MCP 客户端
├── anythingllm_mcp.py        # AnythingLLM MCP 服务器
├── anythingllm_README.md     # 详细文档
├── anythingllm_streaming_client.py  # 流式客户端
├── anythingllm_streaming_mcp.py     # 流式服务器
├── test_anythingllm_mcp.py   # 测试脚本
```

## 快速开始

1. 安装依赖：
   ```bash
   # 使用 Python 脚本安装（推荐）
   python install_dependencies.py
   
   # 或者使用批处理文件安装
   install_dependencies.bat
   
   # 或者手动安装
   pip install fastmcp httpx python-dotenv
   ```

2. 配置环境变量：
   编辑 `.env` 文件，设置您的AnythingLLM API密钥、基础URL和工作区名称。

3. 验证环境配置：
   ```bash
   verify_mcp.bat
   ```

4. 启动MCP服务器：
   ```bash
   run_mcp.bat
   ```

5. 运行示例：
   ```bash
   run_example.bat
   ```

## 详细文档

请参阅 [anythingllm_README.md](anythingllm_README.md) 获取详细的使用说明和API参考。

## 在其他项目中使用

要在其他项目中使用AnythingLLM MCP工具，只需将AnythingLLM_MCP目录添加到Python路径中：

```python
import sys
from pathlib import Path

# 添加 AnythingLLM_MCP 目录到 sys.path
ANYTHINGLLM_MCP_DIR = Path(r"D:\Codes\mcp\my_mcp_server\AnythingLLM_MCP")
sys.path.append(str(ANYTHINGLLM_MCP_DIR))

# 导入 AnythingLLM MCP 模块
from anythingllm_mcp import mcp
from fastmcp import Client

# 使用 MCP 工具
async with Client(mcp) as client:
    response = await client.call_tool("query_knowledge_base", {"prompt": "你的问题"})
    print(response.data)
```