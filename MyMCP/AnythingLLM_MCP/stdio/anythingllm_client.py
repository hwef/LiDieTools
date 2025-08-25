"""
AnythingLLM MCP Client Example

This example demonstrates how to use the AnythingLLM MCP client to interact with the AnythingLLM RAG server.
"""

import asyncio
import sys
import os
from typing import Dict, Any, List

# Add the parent directory to sys.path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from fastmcp import Client
from anythingllm_mcp import mcp

async def print_separator(title: str = None):
    """Print a separator line with an optional title."""
    width = 60
    if title:
        print(f"\n{'-' * ((width - len(title) - 2) // 2)} {title} {'-' * ((width - len(title) - 2) // 2)}")
    else:
        print(f"\n{'-' * width}")

async def main():
    print("\nAnythingLLM MCP Client Example")
    print("==============================")
    
    # Connect to the server
    async with Client(mcp) as client:
        # Check server status
        await print_separator("Server Status")
        try:
            status = await client.read_resource("anythingllm://status")
            print(f"Server status: {status[0].text}")
        except Exception as e:
            print(f"Error reading server status: {e}")
        
        # List available tools
        await print_separator("Available Tools")
        tools = await client.list_tools()
        for tool in tools:
            print(f"- {tool.name}: {tool.description}")
        
        # Get workspace info
        await print_separator("Workspace Info")
        try:
            workspace_info = await client.call_tool("get_workspace_info")
            print(f"Workspace info: {workspace_info.data}")
        except Exception as e:
            print(f"Error getting workspace info: {e}")
        
        # List documents
        await print_separator("Documents")
        try:
            documents = await client.call_tool("list_documents")
            if documents.data:
                print(f"Found {len(documents.data)} documents:")
                for doc in documents.data:
                    print(f"- {doc.get('name', 'Unknown')} (ID: {doc.get('id', 'Unknown')})")
            else:
                print("No documents found in workspace")
        except Exception as e:
            print(f"Error listing documents: {e}")
        
        # Query the knowledge base
        await print_separator("Knowledge Base Query")
        query = "TensorRT C++ 最小案例代码"
        print(f"Query: {query}")
        try:
            response = await client.call_tool("query_knowledge_base", {"prompt": query})
            print(f"Response: {response.data}")
        except Exception as e:
            print(f"Error querying knowledge base: {e}")

if __name__ == "__main__":
    asyncio.run(main())