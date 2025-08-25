import asyncio, os, json
import httpx
from dotenv import load_dotenv

load_dotenv()

API_KEY   = os.getenv("ANYTHINGLLM_API_KEY")
BASE_URL  = os.getenv("ANYTHINGLLM_BASE_URL", "http://localhost:3001")
WORKSPACE = os.getenv("WORKSPACE_NAME", "my")

HEADERS = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json",
}

async def test_query(prompt: str = "CUDA matmul demo"):
    url = f"{BASE_URL}/api/v1/workspace/{WORKSPACE}/chat"
    payload = {"message": prompt, "mode": "query"}

    async with httpx.AsyncClient(timeout=30) as client:
        r = await client.post(url, headers=HEADERS, json=payload)
        r.raise_for_status()
        data = r.json()

    print("=== AnythingLLM 原始返回 ===")
    print(json.dumps(data, ensure_ascii=False, indent=2))

    print("\n=== 提取文本 ===")
    print(data.get("textResponse", ""))

if __name__ == "__main__":
    asyncio.run(test_query(" Tensorrt c++ 最小案例代码"))