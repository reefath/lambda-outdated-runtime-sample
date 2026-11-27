"""Nightly report job (Python 3.13).

Python 3.13 compatibility notes:
  - collections.abc.Mapping replaces collections.Mapping (report/merge.py).
  - LooseVersion-style ordering is implemented locally; distutils is gone (report/versions.py).
  - importlib.util replaces imp (report/plugins.py).
  - configparser.ConfigParser replaces SafeConfigParser (report/config.py).
  - unittest assertEqual / assertRegex replace removed aliases (tests/).
  - datetime.now(timezone.utc) and asyncio.run() replace deprecated calls (report/clock.py).
"""
import json

import boto3

from report.clock import run_at, stamp
from report.config import load_settings
from report.merge import deep_merge
from report.plugins import load_plugin
from report.versions import newest


def handler(event, context):
    settings = load_settings()
    overrides = (event or {}).get("overrides", {})
    merged = deep_merge(settings, overrides)
    who = boto3.client("sts").get_caller_identity()["Account"]
    plugin = load_plugin("summary")
    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "account": who,
                "generated": stamp(),
                "ran_at": run_at(),
                "newest_schema": newest(["1.2.0", "1.10.1", "1.9"]),
                "settings": merged,
                "summary": plugin.summarize(merged),
            }
        ),
    }
