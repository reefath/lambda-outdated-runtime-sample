import asyncio
import datetime


def stamp():
    return datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None).isoformat() + "Z"


async def _now():
    return stamp()


def run_at():
    return asyncio.run(_now())
