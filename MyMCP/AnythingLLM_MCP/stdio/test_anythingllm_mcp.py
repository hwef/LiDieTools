"""
AnythingLLM MCP Test Script

This script tests the AnythingLLM MCP server by running both the regular and streaming clients.
"""

import asyncio
import os
import sys
import subprocess
from pathlib import Path

# Get the absolute path to the Python interpreter
PYTHON_PATH = sys.executable
CURRENT_DIR = Path(os.path.dirname(os.path.abspath(__file__)))

def print_header(title):
    """Print a header with a title."""
    print("\n" + "=" * 80)
    print(f" {title} ".center(80, "="))
    print("=" * 80 + "\n")

async def run_command(cmd, cwd=None):
    """Run a command and print its output."""
    process = await asyncio.create_subprocess_exec(
        *cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
        cwd=cwd
    )
    
    stdout, stderr = await process.communicate()
    
    if stdout:
        print(stdout.decode())
    if stderr:
        print(f"ERROR: {stderr.decode()}")
    
    return process.returncode

async def test_regular_client():
    """Test the regular AnythingLLM MCP client."""
    print_header("Testing Regular AnythingLLM MCP Client")
    
    cmd = [PYTHON_PATH, str(CURRENT_DIR / "anythingllm_client.py")]
    return await run_command(cmd, cwd=CURRENT_DIR)

async def test_streaming_client():
    """Test the streaming AnythingLLM MCP client."""
    print_header("Testing Streaming AnythingLLM MCP Client")
    
    cmd = [PYTHON_PATH, str(CURRENT_DIR / "anythingllm_streaming_client.py")]
    return await run_command(cmd, cwd=CURRENT_DIR)

async def main():
    """Main function to run the tests."""
    print_header("AnythingLLM MCP Test Script")
    
    # Check if .env file exists
    env_file = CURRENT_DIR / ".env"
    
    if not env_file.exists():
        print(f"Error: .env file not found at {env_file}")
        print("Please create a .env file with your AnythingLLM credentials.")
        return
    
    # Run the tests
    regular_result = await test_regular_client()
    streaming_result = await test_streaming_client()
    
    # Print summary
    print_header("Test Summary")
    print(f"Regular client test: {'SUCCESS' if regular_result == 0 else 'FAILED'}")
    print(f"Streaming client test: {'SUCCESS' if streaming_result == 0 else 'FAILED'}")

if __name__ == "__main__":
    asyncio.run(main())