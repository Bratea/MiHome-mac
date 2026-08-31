#!/usr/bin/env python3
"""Small JSON command bridge between the native macOS shell and MijiaService.

The UI never imports the semi-public mijiaAPI package directly.  Keeping that
boundary here means protocol upgrades remain isolated in app.core.service.
"""

from __future__ import annotations

import argparse
import json
import signal
import sys
from dataclasses import asdict
from typing import Any

from app.core.service import MijiaService


def _json_argument(raw: str | None) -> Any:
    return json.loads(raw) if raw else None


def main() -> None:
    parser = argparse.ArgumentParser()
    subcommands = parser.add_subparsers(dest="command", required=True)

    detail = subcommands.add_parser("detail")
    detail.add_argument("--did", required=True)

    read = subcommands.add_parser("read-props")
    read.add_argument("--did", required=True)
    read.add_argument("--names", required=True)

    write = subcommands.add_parser("write-prop")
    write.add_argument("--did", required=True)
    write.add_argument("--name", required=True)
    write.add_argument("--value", required=True)

    action = subcommands.add_parser("run-action")
    action.add_argument("--did", required=True)
    action.add_argument("--name", required=True)
    action.add_argument("--params")

    args = parser.parse_args()
    service = MijiaService()
    if args.command == "detail":
        result = asdict(service.device_detail(args.did))
    elif args.command == "read-props":
        result = service.read_props(args.did, _json_argument(args.names))
    elif args.command == "write-prop":
        service.write_prop(args.did, args.name, _json_argument(args.value))
        result = {"ok": True}
    else:
        service.run_action(args.did, args.name, _json_argument(args.params))
        result = {"ok": True}
    print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    try:
        signal.signal(signal.SIGALRM, lambda _signal, _frame: (_ for _ in ()).throw(TimeoutError("米家服务响应超时，请检查网络与设备状态。")))
        signal.alarm(20)
        main()
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
    finally:
        signal.alarm(0)
