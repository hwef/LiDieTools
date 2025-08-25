"""
FastMCP server for AnythingLLM integration.
"""

import os
from fastmcp import FastMCP
import httpx
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

API_KEY = os.getenv("ANYTHINGLLM_API_KEY")
BASE_URL = os.getenv("ANYTHINGLLM_BASE_URL", "http://localhost:3001")
WORKSPACE = os.getenv("WORKSPACE_NAME", "my")

HEADERS = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json",
}

mcp = FastMCP("AnythingLLM Server")


@mcp.tool
async def query_anythingllm(prompt: str) -> dict:
    """Query AnythingLLM with a prompt."""
    url = f"{BASE_URL}/api/v1/workspace/{WORKSPACE}/chat"
    payload = {"message": prompt, "mode": "query"}

    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.post(url, headers=HEADERS, json=payload)
        response.raise_for_status()
        return response.json()

        # return {"name": "query_anythingllm", "arguments": response.json()}


if __name__ == "__main__":
    print("Starting server on port 8003 with SSE transport...")
    print(f"API_KEY: {API_KEY}")
    print(f"BASE_URL: {BASE_URL}")
    mcp.run(transport="sse", port=8003)