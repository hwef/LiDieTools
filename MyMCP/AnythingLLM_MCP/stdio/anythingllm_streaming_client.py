"""
AnythingLLM MCP Streaming Client Example

This example demonstrates how to use the AnythingLLM MCP client to interact with the AnythingLLM RAG server
with streaming support.
"""

import asyncio
import sys
import os
from typing import Dict, Any, List

# Add the parent directory to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from fastmcp import Client
from anythingllm_streaming_mcp import mcp

async def print_separator(title: str = None):
    """Print a separator line with an optional title."""
    width = 60
    if title:
        print(f"\n{'-' * ((width - len(title) - 2) // 2)} {title} {'-' * ((width - len(title) - 2) // 2)}")
    else:
        print(f"\n{'-' * width}")

async def main():
    print("\nAnythingLLM MCP Streaming Client Example")
    print("=======================================")
    
    # Connect to the server
    async with Client(mcp) as client:
        # Get system info
        await print_separator("System Info")
        try:
            system_info = await client.read_resource("anythingllm://system/info")
            print(f"System info: {system_info[0].text}")
        except Exception as e:
            print(f"Error reading system info: {e}")
        
        # List available tools
        await print_separator("Available Tools")
        tools = await client.list_tools()
        for tool in tools:
            print(f"- {tool.name}: {tool.description}")
        
        # List workspaces
        await print_separator("Workspaces")
        try:
            workspaces = await client.call_tool("list_workspaces")
            if workspaces.data:
                print(f"Found {len(workspaces.data)} workspaces:")
                for workspace in workspaces.data:
                    print(f"- {workspace.get('name', 'Unknown')} (ID: {workspace.get('id', 'Unknown')})")
            else:
                print("No workspaces found")
        except Exception as e:
            print(f"Error listing workspaces: {e}")
        
        # Get embedding models
        await print_separator("Embedding Models")
        try:
            embedding_models = await client.call_tool("get_embedding_models")
            if embedding_models.data:
                print(f"Found {len(embedding_models.data)} embedding models:")
                for model in embedding_models.data:
                    print(f"- {model.get('name', 'Unknown')}")
            else:
                print("No embedding models found")
        except Exception as e:
            print(f"Error getting embedding models: {e}")
        
        # Get LLM models
        await print_separator("LLM Models")
        try:
            llm_models = await client.call_tool("get_llm_models")
            if llm_models.data:
                print(f"Found {len(llm_models.data)} LLM models:")
                for model in llm_models.data:
                    print(f"- {model.get('name', 'Unknown')}")
            else:
                print("No LLM models found")
        except Exception as e:
            print(f"Error getting LLM models: {e}")
        
        # Query the knowledge base with streaming
        await print_separator("Knowledge Base Streaming Query")
        query = "TensorRT C++ 最小案例代码"
        print(f"Query: {query}")
        try:
            print("\nStreaming response:")
            async for chunk in client.call_tool("query_knowledge_base_stream", {"prompt": query}):
                print(chunk.text, end="", flush=True)
            print("\n")
        except Exception as e:
            print(f"Error querying knowledge base: {e}")

if __name__ == "__main__":
    asyncio.run(main())