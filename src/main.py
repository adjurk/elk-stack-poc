from fastapi import FastAPI
import logging
import json_logging
import asyncio, random, sys, os

app = FastAPI()
json_logging.init_fastapi(enable_json=True)
json_logging.init_request_instrument(app)

logger = logging.getLogger()
logger.setLevel(logging.INFO)
logger.addHandler(logging.StreamHandler(sys.stdout))

wait_time_min = int(os.getenv('WAIT_TIME_MIN', 1))
wait_time_max = int(os.getenv('WAIT_TIME_MAX', 5))

async def produce_log():
    wait_time = 0
    while True:
        logger.info(f"Here I am after waiting {wait_time} seconds!")
        wait_time = random.randint(wait_time_min, wait_time_max)
        await asyncio.sleep(wait_time)

@app.on_event("startup")
async def startup_event():
    asyncio.create_task(produce_log())

@app.get("/health")
def get_health():
    return {"health": "alive"}