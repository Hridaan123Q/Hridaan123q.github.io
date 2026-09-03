from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import logging

app = FastAPI(title="JARVIS Backend")
logger = logging.getLogger(__name__)

class CommandRequest(BaseModel):
    command: str

class CommandResponse(BaseModel):
    status: str
    result: str

from jarvis_backend.agent import Agent

agent = Agent()

@app.post("/execute", response_model=CommandResponse)
async def execute_command(request: CommandRequest):
    try:
        result = await agent.execute_task(request.command)
        logger.info(f"Executed: {request.command}")
        return CommandResponse(status="success", result=result)
    except Exception as e:
        logger.error(f"Error executing command: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
