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
import time
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

    statistics = subcommands.add_parser("statistics")
    statistics.add_argument("--did", required=True)
    statistics.add_argument("--key", required=True)
    statistics.add_argument("--data-type", required=True)
    statistics.add_argument("--limit", type=int, default=6)
    statistics.add_argument("--days", type=int, default=31)

    subcommands.add_parser("scenes")
    scene = subcommands.add_parser("run-scene")
    scene.add_argument("--scene-id", required=True)
    scene.add_argument("--home-id", required=True)

    subcommands.add_parser("login-status")
    subcommands.add_parser("qr-login-begin")
    qr_wait = subcommands.add_parser("qr-login-wait")
    qr_wait.add_argument("--payload", required=True)
    subcommands.add_parser("sync-devices")

    args = parser.parse_args()
    service = MijiaService()
    if args.command == "login-status":
        result = {"available": service.login_status()}
    elif args.command == "qr-login-begin":
        login_data = service.qr_login_begin()
        result = {
            "requires_scan": login_data is not None,
            "login_url": login_data.get("loginUrl") if login_data else None,
            "payload": json.dumps(login_data, ensure_ascii=False) if login_data else None,
        }
    elif args.command == "qr-login-wait":
        service.qr_login_wait(_json_argument(args.payload))
        result = {"ok": True}
    elif args.command == "sync-devices":
        devices = service.list_devices()
        dids = [device.did for device in devices]
        result = {
            "version": 1,
            "devices": [asdict(device) for device in devices],
            "known_power": service.power_states(dids),
            "metrics": {key: value for key, value in service.read_metrics(dids).items() if value},
        }
    elif args.command == "detail":
        result = asdict(service.device_detail(args.did))
    elif args.command == "read-props":
        result = service.read_props(args.did, _json_argument(args.names))
    elif args.command == "write-prop":
        service.write_prop(args.did, args.name, _json_argument(args.value))
        result = {"ok": True}
    elif args.command == "statistics":
        now = int(time.time())
        raw_entries = service.get_statistics(
            args.did, args.key, args.data_type, args.limit,
            now - args.days * 24 * 3600, now,
        )
        entries = []
        for item in raw_entries:
            try:
                values = json.loads(item.get("value", "[]"))
                value = float(values[0]) if values else None
            except (TypeError, ValueError, json.JSONDecodeError, IndexError):
                value = None
            entries.append({"timestamp": int(item.get("time", 0)), "value": value})
        result = {"entries": entries}
    elif args.command == "scenes":
        result = [
            {"id": str(scene["scene_id"]), "name": scene.get("name", "未命名场景"), "home_id": str(scene["home_id"])}
            for scene in service.list_scenes()
        ]
    elif args.command == "run-scene":
        result = {"ok": service.run_scene(args.scene_id, args.home_id)}
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
