"""
AnythingLLM MCP Server with Streaming Support

This example demonstrates how to create a FastMCP server that uses AnythingLLM as the backend
for RAG (Retrieval Augmented Generation) capabilities with streaming support.

Requirements:
- AnythingLLM running locally or remotely
- API key for AnythingLLM
- A workspace configured in AnythingLLM
"""

import asyncio
import os
import json
import sys
import httpx
from pathlib import Path
from typing import Optional, List, Dict, Any, AsyncGenerator
from dotenv import load_dotenv

# 添加当前目录到 sys.path
sys.path.append(str(Path(__file__).parent))

from fastmcp import FastMCP
from mcp.types import TextContent, Content

# Load environment variables
load_dotenv()

# AnythingLLM configuration
API_KEY = os.getenv("ANYTHINGLLM_API_KEY")
BASE_URL = os.getenv("ANYTHINGLLM_BASE_URL", "http://localhost:3001")
WORKSPACE = os.getenv("WORKSPACE_NAME", "my")
if not WORKSPACE:
    WORKSPACE = os.getenv("WORKSPACE", "my")

# Create FastMCP server
mcp = FastMCP(
    "AnythingLLM RAG Server with Streaming",
    dependencies=["httpx", "python-dotenv"]
)

# Headers for AnythingLLM API requests
HEADERS = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json",
}

@mcp.tool
async def query_knowledge_base_stream(prompt: str) -> AsyncGenerator[Content, None]:
    """
    Query the AnythingLLM knowledge base with a prompt and stream the response.
    
    Args:
        prompt: The query to send to AnythingLLM
        
    Yields:
        Streaming content from AnythingLLM
    """
    url = f"{BASE_URL}/api/v1/workspace/{WORKSPACE}/chat/stream"
    payload = {"message": prompt, "mode": "query"}
    
    try:
        async with httpx.AsyncClient(timeout=60) as client:
            async with client.stream("POST", url, headers=HEADERS, json=payload) as response:
                response.raise_for_status()
                
                buffer = ""
                async for chunk in response.aiter_text():
                    if chunk.strip():
                        # AnythingLLM sends SSE data in the format: data: {...}
                        if chunk.startswith("data:"):
                            data_str = chunk[5:].strip()
                            try:
                                data = json.loads(data_str)
                                if "textResponse" in data:
                                    text_chunk = data["textResponse"]
                                    yield Content(text=text_chunk)
                                    buffer += text_chunk
                            except json.JSONDecodeError:
                                # Handle non-JSON data
                                yield Content(text=data_str)
                                buffer += data_str
                        else:
                            # Handle raw text
                            yield Content(text=chunk)
                            buffer += chunk
                
                # Return the final buffer as metadata
                yield Content(text="", meta={"complete_response": buffer})
    except Exception as e:
        yield Content(text=f"Error querying knowledge base: {str(e)}")

@mcp.tool
async def list_workspaces() -> List[Dict[str, Any]]:
    """
    List all workspaces in AnythingLLM.
    
    Returns:
        A list of workspaces
    """
    url = f"{BASE_URL}/api/v1/workspaces"
    
    try:
        async with httpx.AsyncClient(timeout=30) as client:
            r = await client.get(url, headers=HEADERS)
            r.raise_for_status()
            data = r.json()
        
        return data.get("workspaces", [])
    except Exception as e:
        return [{"error": f"Error listing workspaces: {str(e)}"}]

@mcp.tool
async def create_workspace(name: str, description: Optional[str] = None) -> Dict[str, Any]:
    """
    Create a new workspace in AnythingLLM.
    
    Args:
        name: Name of the workspace
        description: Optional description of the workspace
        
    Returns:
        Response from the create operation
    """
    url = f"{BASE_URL}/api/v1/workspace"
    payload = {"name": name}
    
    if description:
        payload["description"] = description
    
    try:
        async with httpx.AsyncClient(timeout=30) as client:
            r = await client.post(url, headers=HEADERS, json=payload)
            r.raise_for_status()
            return r.json()
    except Exception as e:
        return {"error": f"Error creating workspace: {str(e)}"}

@mcp.tool
async def get_embedding_models() -> List[Dict[str, Any]]:
    """
    Get a list of available embedding models in AnythingLLM.
    
    Returns:
        A list of embedding models
    """
    url = f"{BASE_URL}/api/v1/system/embedding-models"
    
    try:
        async with httpx.AsyncClient(timeout=30) as client:
            r = await client.get(url, headers=HEADERS)
            r.raise_for_status()
            data = r.json()
        
        return data.get("embeddingModels", [])
    except Exception as e:
        return [{"error": f"Error getting embedding models: {str(e)}"}]

@mcp.tool
async def get_llm_models() -> List[Dict[str, Any]]:
    """
    Get a list of available LLM models in AnythingLLM.
    
    Returns:
        A list of LLM models
    """
    url = f"{BASE_URL}/api/v1/system/llm-models"
    
    try:
        async with httpx.AsyncClient(timeout=30) as client:
            r = await client.get(url, headers=HEADERS)
            r.raise_for_status()
            data = r.json()
        
        return data.get("llmModels", [])
    except Exception as e:
        return [{"error": f"Error getting LLM models: {str(e)}"}]

@mcp.resource(uri="anythingllm://system/info")
async def get_system_info():
    """Return system information from AnythingLLM."""
    try:
        url = f"{BASE_URL}/api/v1/system"
        async with httpx.AsyncClient(timeout=10) as client:
            r = await client.get(url, headers=HEADERS)
            r.raise_for_status()
            return r.json()
    except Exception as e:
        return {
            "status": "error",
            "error": str(e)
        }

 

if __name__ == "__main__":
    mcp.run()