"""
AnythingLLM MCP Server Example

This example demonstrates how to create a FastMCP server that uses AnythingLLM as the backend
for RAG (Retrieval Augmented Generation) capabilities.

Requirements:
- AnythingLLM running locally or remotely
- API key for AnythingLLM
- A workspace configured in AnythingLLM

Environment variables:
- ANYTHINGLLM_API_KEY: API key for AnythingLLM
- ANYTHINGLLM_BASE_URL: Base URL for AnythingLLM API (default: http://localhost:3001)
- WORKSPACE_NAME: Name of the workspace in AnythingLLM (default: my)
"""

import asyncio
import os
import json
import sys
from pathlib import Path

# 添加当前目录到 sys.path
sys.path.append(str(Path(__file__).parent))
import httpx
from typing import Optional, List, Dict, Any
from dotenv import load_dotenv

from fastmcp import FastMCP
from mcp.types import TextContent

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
    "AnythingLLM RAG Server",
    dependencies=["httpx", "python-dotenv"]
)

# Headers for AnythingLLM API requests
HEADERS = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json",
}

@mcp.tool
async def query_knowledge_base(prompt: str) -> str:
    """
    Query the AnythingLLM knowledge base with a prompt.
    
    Args:
        prompt: The query to send to AnythingLLM
        
    Returns:
        The response from AnythingLLM
    """
    url = f"{BASE_URL}/api/v1/workspace/{WORKSPACE}/chat"
    payload = {"message": prompt, "mode": "query"}
    
    try:
        async with httpx.AsyncClient(timeout=30) as client:
            r = await client.post(url, headers=HEADERS, json=payload)
            r.raise_for_status()
            data = r.json()
        
        # Extract the text response
        return data.get("textResponse", "No response received")
    except Exception as e:
        return f"Error querying knowledge base: {str(e)}"

@mcp.tool
async def list_documents() -> List[Dict[str, Any]]:
    """
    List all documents in the AnythingLLM workspace.
    
    Returns:
        A list of documents in the workspace
    """
    url = f"{BASE_URL}/api/v1/workspace/{WORKSPACE}/documents"
    
    try:
        async with httpx.AsyncClient(timeout=30) as client:
            r = await client.get(url, headers=HEADERS)
            r.raise_for_status()
            data = r.json()
        
        return data.get("documents", [])
    except Exception as e:
        return [{"error": f"Error listing documents: {str(e)}"}]

@mcp.tool
async def upload_document(file_path: str, chunk_size: int = 1500) -> Dict[str, Any]:
    """
    Upload a document to the AnythingLLM workspace.
    
    Args:
        file_path: Path to the file to upload
        chunk_size: Size of chunks for processing (default: 1500)
        
    Returns:
        Response from the upload operation
    """
    url = f"{BASE_URL}/api/v1/workspace/{WORKSPACE}/documents/upload"
    
    try:
        if not os.path.exists(file_path):
            return {"error": f"File not found: {file_path}"}
        
        file_name = os.path.basename(file_path)
        
        # AnythingLLM expects multipart/form-data
        files = {"file": (file_name, open(file_path, "rb"))}
        data = {"chunkSize": str(chunk_size)}
        
        async with httpx.AsyncClient(timeout=60) as client:
            # Remove the Content-Type header for multipart/form-data
            headers = {k: v for k, v in HEADERS.items() if k != "Content-Type"}
            r = await client.post(url, headers=headers, files=files, data=data)
            r.raise_for_status()
            return r.json()
    except Exception as e:
        return {"error": f"Error uploading document: {str(e)}"}

@mcp.tool
async def delete_document(document_id: str) -> Dict[str, Any]:
    """
    Delete a document from the AnythingLLM workspace.
    
    Args:
        document_id: ID of the document to delete
        
    Returns:
        Response from the delete operation
    """
    url = f"{BASE_URL}/api/v1/workspace/{WORKSPACE}/documents/{document_id}"
    
    try:
        async with httpx.AsyncClient(timeout=30) as client:
            r = await client.delete(url, headers=HEADERS)
            r.raise_for_status()
            return r.json()
    except Exception as e:
        return {"error": f"Error deleting document: {str(e)}"}

@mcp.tool
async def get_workspace_info() -> Dict[str, Any]:
    """
    Get information about the current AnythingLLM workspace.
    
    Returns:
        Workspace information
    """
    url = f"{BASE_URL}/api/v1/workspace/{WORKSPACE}"
    
    try:
        async with httpx.AsyncClient(timeout=30) as client:
            r = await client.get(url, headers=HEADERS)
            r.raise_for_status()
            return r.json()
    except Exception as e:
        return {"error": f"Error getting workspace info: {str(e)}"}

@mcp.resource(uri="anythingllm://status")
async def get_status():
    """Return the current status of the AnythingLLM connection."""
    try:
        url = f"{BASE_URL}/api/v1/system"
        async with httpx.AsyncClient(timeout=10) as client:
            r = await client.get(url, headers=HEADERS)
            r.raise_for_status()
            return {
                "status": "connected",
                "version": r.json().get("version", "unknown"),
                "workspace": WORKSPACE,
                "base_url": BASE_URL
            }
    except Exception as e:
        return {
            "status": "disconnected",
            "error": str(e),
            "workspace": WORKSPACE,
            "base_url": BASE_URL
        }



if __name__ == "__main__":
    mcp.run()