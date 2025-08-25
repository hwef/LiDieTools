"""
FastMCP server for AnythingLLM – full-featured
"""

import os
import asyncio
import zipfile
import tempfile
import fnmatch
from pathlib import Path
from typing import List, Optional, Set
import gitignore_parser
import datetime

import httpx
from fastmcp import FastMCP
from dotenv import load_dotenv
import aiofiles

load_dotenv()

API_KEY = os.getenv("ANYTHINGLLM_API_KEY")
BASE_URL = os.getenv("ANYTHINGLLM_BASE_URL", "http://localhost:3001")
print(API_KEY)
print(BASE_URL)
HEADERS = {
    "Authorization": f"Bearer {API_KEY}",
}

mcp = FastMCP("AnythingLLM Full Server")

# ------------------------------------------------------------------
# 内部辅助
# ------------------------------------------------------------------
async def _anything_request(
    method: str, endpoint: str, *, json=None, data=None, files=None, max_retries: int = 3
):
    """
    向 AnythingLLM 服务器发送请求，并处理可能的连接错误
    
    Args:
        method: HTTP 方法
        endpoint: API 端点
        json: JSON 数据
        data: 表单数据
        files: 文件数据
        max_retries: 最大重试次数
    
    Returns:
        服务器响应的 JSON 数据
    
    Raises:
        Exception: 如果请求失败
    """
    url = f"{BASE_URL.rstrip('/')}/{endpoint.lstrip('/')}"
    retries = 0
    last_exception = None
    
    while retries <= max_retries:
        try:
            async with httpx.AsyncClient(timeout=120) as client:
                r = await client.request(
                    method, url, headers=HEADERS, json=json, data=data, files=files
                )
                r.raise_for_status()
                return r.json()
        except httpx.ConnectError as e:
            last_exception = e
            retries += 1
            if retries <= max_retries:
                print(f"连接失败，正在重试 ({retries}/{max_retries})...")
                await asyncio.sleep(1)  # 等待 1 秒后重试
        except Exception as e:
            last_exception = e
            break
    
    # 如果所有重试都失败，抛出异常
    error_msg = f"请求失败: {str(last_exception)}"
    print(error_msg)
    raise Exception(error_msg)

# 通用MIME类型映射，支持任意文件类型
MIME_TYPES = {
    ".txt": "text/plain",
    ".md": "text/plain",
    ".org": "text/plain",
    ".adoc": "text/plain",
    ".rst": "text/plain",
    ".html": "text/html",
    ".htm": "text/html",
    ".css": "text/css",
    ".js": "application/javascript",
    ".json": "application/json",
    ".xml": "application/xml",
    ".csv": "text/csv",
    ".docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ".doc": "application/msword",
    ".pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    ".ppt": "application/vnd.ms-powerpoint",
    ".xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    ".xls": "application/vnd.ms-excel",
    ".odt": "application/vnd.oasis.opendocument.text",
    ".odp": "application/vnd.oasis.opendocument.presentation",
    ".ods": "application/vnd.oasis.opendocument.spreadsheet",
    ".pdf": "application/pdf",
    ".zip": "application/zip",
    ".rar": "application/x-rar-compressed",
    ".7z": "application/x-7z-compressed",
    ".tar": "application/x-tar",
    ".gz": "application/gzip",
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".png": "image/png",
    ".gif": "image/gif",
    ".bmp": "image/bmp",
    ".svg": "image/svg+xml",
    ".ico": "image/x-icon",
    ".mp3": "audio/mpeg",
    ".wav": "audio/wav",
    ".ogg": "audio/ogg",
    ".flac": "audio/flac",
    ".mp4": "video/mp4",
    ".avi": "video/x-msvideo",
    ".mov": "video/quicktime",
    ".wmv": "video/x-ms-wmv",
    ".flv": "video/x-flv",
    ".webm": "video/webm",
    ".mpeg": "video/mpeg",
    ".mkv": "video/x-matroska",
    ".mbox": "application/mbox",
    ".epub": "application/epub+zip",
    ".py": "text/x-python",
    ".java": "text/x-java-source",
    ".c": "text/x-c",
    ".cpp": "text/x-c++",
    ".h": "text/x-c",
    ".cs": "text/x-csharp",
    ".go": "text/x-go",
    ".rs": "text/x-rust",
    ".php": "text/x-php",
    ".rb": "text/x-ruby",
    ".pl": "text/x-perl",
    ".sh": "text/x-shellscript",
    ".bat": "text/x-shellscript",
    ".ps1": "text/x-powershell",
    ".sql": "application/sql",
    ".yml": "application/x-yaml",
    ".yaml": "application/x-yaml",
    ".toml": "application/toml",
    ".ini": "text/plain",
    ".cfg": "text/plain",
    ".conf": "text/plain",
    ".log": "text/plain"
}

# ------------------------------------------------------------------
# FastMCP Tools
# ------------------------------------------------------------------
@mcp.tool
async def list_workspaces() -> List[str]:
    """
    列出服务器上所有 workspace 名称
    
    Returns:
        List[str]: 包含所有 workspace 名称的列表
        
    Example:
        workspaces = await list_workspaces()
    """
    data = await _anything_request("GET", "/api/v1/workspaces")
    return [ws["name"] for ws in data["workspaces"]]


@mcp.tool
async def create_workspace(name: str) -> dict:
    """
    新建 workspace
    
    Args:
        name (str): 要创建的 workspace 的名称
        
    Returns:
        dict: 包含创建结果的字典
        
    Example:
        result = await create_workspace("my_new_workspace")
    """
    return await _anything_request("POST", "/api/v1/workspace/new", json={"name": name})

# ---------- upload_file ----------
@mcp.tool
async def upload_file(workspace: str, file_path: str) -> dict:
    """
    上传单个文件到指定的 workspace（支持任意文件类型）
    
    Args:
        workspace (str): 目标 workspace 的名称
        file_path (str): 要上传的本地文件路径
        
    Returns:
        dict: 包含上传状态和文档位置的结果字典
    """
    try:
        p = Path(file_path).expanduser().resolve()
        
        # 检查文件是否存在
        if not p.exists() or not p.is_file():
            return {"status": "error", "message": f"文件不存在: {file_path}"}
        
        # 获取正确的MIME类型
        mime_type = get_mime_type(p)
        
        # 异步读取文件并上传
        async with aiofiles.open(p, "rb") as f:
            file_content = await f.read()
            
            # 准备文件上传数据
            files = {"file": (p.name, file_content, mime_type)}
            
            try:
                doc = await _anything_request(
                    "POST", "/api/v1/document/upload",
                    files=files
                )
            except Exception as e:
                return {"status": "error", "message": f"上传文件失败: {str(e)}"}
        
        # 验证响应结构
        if not doc or not isinstance(doc, dict) or "documents" not in doc:
            return {"status": "error", "message": "无效的上传响应"}
            
        if not doc["documents"] or len(doc["documents"]) == 0:
            return {"status": "error", "message": "未找到上传的文档信息"}
            
        if "location" not in doc["documents"][0]:
            return {"status": "error", "message": "文档位置信息缺失"}
            
        # 获取文档位置
        location = doc["documents"][0]["location"]        # e.g. custom-documents/xxx-hash.json
        
        # 更新嵌入
        try:
            await _anything_request(
                "POST", f"/api/v1/workspace/{workspace}/update-embeddings",
                json={"adds": [location]}
            )
        except Exception as e:
            return {"status": "partial", "message": f"上传成功但更新嵌入失败: {str(e)}", "location": location}
        
        return {"status": "indexed", "location": location, "file_name": p.name}
        
    except Exception as e:
        return {"status": "error", "message": f"处理上传文件时发生错误: {str(e)}"}


# ---------- upload_folder ----------
@mcp.tool
async def upload_folder(workspace: str, folder_path: str) -> dict:
    """
    上传整个文件夹到指定的 workspace（支持任意文件类型）
    
    Args:
        workspace (str): 目标 workspace 的名称
        folder_path (str): 要上传的本地文件夹路径
        
    Returns:
        dict: 包含上传状态、处理文件数量以及详细日志的结果字典
    """
    try:
        import datetime
        
        root = Path(folder_path).expanduser().resolve()
        
        # 检查文件夹是否存在
        if not root.exists() or not root.is_dir():
            return {"status": "error", "message": f"文件夹不存在: {folder_path}"}
        
        # 收集所有文件（支持任意类型），自动忽略.gitignore中的内容
        all_files = [f for f in root.rglob("*") if f.is_file()]
        
        # 检查是否存在.gitignore文件并过滤文件
        gitignore_path = root / ".gitignore"
        if gitignore_path.exists() and gitignore_path.is_file():
            try:
                # 使用gitignore_parser创建匹配函数，指定base_dir为根目录
                ignore_match = gitignore_parser.parse_gitignore(gitignore_path, base_dir=root)
                # 过滤掉被.gitignore忽略的文件
                files = [f for f in all_files if not ignore_match(f)]
            except Exception:
                # 如果解析失败，使用所有文件
                files = all_files
        else:
            files = all_files
        
        if not files:
            return {"status": "no files", "message": "未找到符合条件的文件"}

        # 生成带时间戳的文件夹名称
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        folder_name = f"{root.name}_{timestamp}"
        print(f"创建上传目标文件夹: {folder_name}")

        # 逐个上传文件
        uploaded_locations = []
        successful_uploads = 0
        failed_uploads = 0
        
        # 用于记录成功和失败的文件列表
        successful_files = []
        failed_files = []
        
        for file_path in files:
            try:
                # 获取正确的MIME类型
                mime_type = get_mime_type(file_path)
                
                # 异步读取文件并上传
                async with aiofiles.open(file_path, "rb") as f:
                    file_content = await f.read()
                    
                    # 计算相对路径，保持目录结构
                    rel_path = file_path.relative_to(root)
                    # 创建新的文件名：文件夹名/相对路径
                    new_file_name = f"{folder_name}/{rel_path}"
                    
                    # 准备文件上传数据
                    files_upload = {"file": (new_file_name, file_content, mime_type)}
                    
                    try:
                        doc = await _anything_request(
                            "POST", "/api/v1/document/upload",
                            files=files_upload
                        )
                        
                        # 验证响应结构
                        if doc and isinstance(doc, dict) and "documents" in doc:
                            if doc["documents"] and len(doc["documents"]) > 0:
                                if "location" in doc["documents"][0]:
                                    location = doc["documents"][0]["location"]
                                    uploaded_locations.append(location)
                                    successful_uploads += 1
                                    successful_files.append(str(file_path))
                                    print(f"成功上传文件: {file_path}")
                                    continue
                        
                        failed_uploads += 1
                        failed_files.append(str(file_path))
                        print(f"文件上传成功但响应无效: {file_path}")
                        
                    except Exception as e:
                        failed_uploads += 1
                        failed_files.append(str(file_path))
                        print(f"上传文件失败: {file_path}, 错误: {str(e)}")
                        
            except Exception as e:
                failed_uploads += 1
                failed_files.append(str(file_path))
                print(f"处理文件时发生错误: {file_path}, 错误: {str(e)}")
        
        # 打印详细的上传摘要
        print(f"\n===== 文件夹上传摘要 =====")
        print(f"总文件数: {len(files)}")
        print(f"成功上传: {successful_uploads}")
        print(f"上传失败: {failed_uploads}")
        
        if successful_files:
            print(f"\n成功上传的文件:")
            for file in successful_files[:5]:  # 只打印前5个文件，避免输出过多
                print(f"  - {file}")
            if len(successful_files) > 5:
                print(f"  ... 还有 {len(successful_files) - 5} 个文件")
        
        if failed_files:
            print(f"\n上传失败的文件:")
            for file in failed_files[:5]:  # 只打印前5个文件，避免输出过多
                print(f"  - {file}")
            if len(failed_files) > 5:
                print(f"  ... 还有 {len(failed_files) - 5} 个文件")
        print("=========================")
        
        if not uploaded_locations:
            return {"status": "error", "message": "所有文件上传失败", "successful": successful_uploads, "failed": failed_uploads,
                    "successful_files": successful_files, "failed_files": failed_files}
        
        # 批量更新嵌入
        try:
            await _anything_request(
                 "POST", f"/api/v1/workspace/{workspace}/update-embeddings",
                 json={"adds": uploaded_locations}
             )
        except Exception as e:
            print(f"更新嵌入失败: {str(e)}")
            return {"status": "partial", "message": f"文件上传成功但更新嵌入失败: {str(e)}", "successful": successful_uploads, "failed": failed_uploads, 
                    "locations": uploaded_locations, "successful_files": successful_files, "failed_files": failed_files}
        
        print(f"所有文件上传完成，已成功索引 {successful_uploads} 个文件")
        return {"status": "indexed", "successful": successful_uploads, "failed": failed_uploads, "total_files": len(files), 
                "locations": uploaded_locations, "successful_files": successful_files, "failed_files": failed_files,
                "folder_name": folder_name}
        
    except Exception as e:
        error_msg = f"处理上传文件夹时发生错误: {str(e)}"
        print(error_msg)
        return {"status": "error", "message": error_msg}




# 辅助函数: 获取文件MIME类型
def get_mime_type(file_path: Path) -> str:
    """获取文件的MIME类型，优先使用已知映射，未知类型使用通用类型"""
    suffix = file_path.suffix.lower()
    return MIME_TYPES.get(suffix, "application/octet-stream")




@mcp.tool
async def query(workspace: str, prompt: str, mode: str = "query") -> dict:
    """
    向指定 workspace 提问
    
    Args:
        workspace (str): 要查询的 workspace 名称
        prompt (str): 用户的查询内容
        mode (str, optional): 查询模式，可以是 "query" 或 "chat"。默认为 "query"
        
    Returns:
        dict: 包含查询结果的响应字典
        
    Example:
        result = await query("my_workspace", "项目的主要功能是什么？")
        result = await query("my_workspace", "详细解释认证流程", mode="chat")
    """
    payload = {"message": prompt, "mode": mode}
    return await _anything_request(
        "POST", f"/api/v1/workspace/{workspace}/chat", json=payload
    )


 

# ------------------------------------------------------------------
# 入口
# ------------------------------------------------------------------
if __name__ == "__main__":
    print("Starting AnythingLLM-Full server on port 8003 (SSE)...")
    mcp.run(transport="sse", port=8203)