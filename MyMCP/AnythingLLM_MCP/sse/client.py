"""
FastMCP client for testing AnythingLLM server.
"""

import asyncio
from fastmcp import Client


async def main():
    print("Connecting to server...")
    try:
        async with Client("http://localhost:8203/sse") as client:
            print("Connected to server. Calling tool...")
            result = await client.call_tool("list_workspaces", {})
            if hasattr(result, 'content') and len(result.content) > 0:
                text_response = result.content[0].text
                print("Response from AnythingLLM:", text_response)
            else:
                print("Error: No valid response from server.")
    except Exception as e:
        print("Error:", e)


if __name__ == "__main__":
    asyncio.run(main())