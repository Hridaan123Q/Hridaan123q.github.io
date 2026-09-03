import os
from openai import AsyncOpenAI

class Agent:
    def __init__(self):
        # Using Google's OpenAI-compatible API endpoint as requested in memories
        self.api_key = os.environ.get("GEMINI_API_KEY", "mock_key")

        # Configure client for Gemini's OpenAI-compatible endpoint
        self.client = AsyncOpenAI(
            api_key=self.api_key,
            base_url="https://generativelanguage.googleapis.com/v1beta/openai/"
        )
        # Using the latest stable Gemini Flash model for fast execution tier
        self.model = "gemini-2.0-flash"

    async def execute_task(self, prompt: str) -> str:
        try:
            # Note: in a real environment this would connect to the actual model
            # For testing/sandbox we return a mock structure if key is 'mock_key'
            if self.api_key == "mock_key":
                return f"Agent simulated execution for: {prompt}"

            response = await self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": "You are JARVIS, a Heterogeneous Distributed Autonomous Agent System."},
                    {"role": "user", "content": prompt}
                ]
            )
            return response.choices[0].message.content
        except Exception as e:
            return f"Agent execution failed: {str(e)}"
