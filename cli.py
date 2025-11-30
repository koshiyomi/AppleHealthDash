import argparse
import getpass
import json
import os
import sys
import time
from typing import Any, Dict, List

CONFIG_DEFAULT_PATH = "config.json"
TOKEN_ENV_VAR = "APPLE_HEALTH_SESSION_TOKEN"


def load_config(path: str) -> Dict[str, Any]:
    try:
        with open(path, "r", encoding="utf-8") as fh:
            return json.load(fh)
    except FileNotFoundError:
        sys.exit(
            f"Config file '{path}' not found. Create it from config.example.json and retry."
        )
    except json.JSONDecodeError as err:
        sys.exit(f"Invalid JSON in config file '{path}': {err}")


def prompt_for_token() -> str:
    token = getpass.getpass(
        prompt=(
            "Enter a short-lived session token (will not be stored on disk): "
        )
    ).strip()
    if not token:
        sys.exit("A session token is required to continue.")
    return token


def resolve_token() -> str:
    token = os.environ.get(TOKEN_ENV_VAR, "").strip()
    if token:
        return token
    return prompt_for_token()


def fetch_metrics(token: str, metrics: List[Dict[str, str]]) -> Dict[str, Any]:
    """Placeholder for fetching metrics from your authorized data source.

    Replace this stub with calls to your own API or file reader. The function
    intentionally avoids persisting the token and only uses it in memory.
    """

    # TODO: Replace with real implementation
    return {metric.get("label", metric.get("name", "metric")): "N/A" for metric in metrics}


def print_metrics(data: Dict[str, Any]) -> None:
    print("\n=== Apple Health Dashboard ===")
    for key, value in data.items():
        print(f"{key}: {value}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Local Apple Health dashboard scaffold. Expects a short-lived session token "
            "from an authorized data source at runtime and avoids storing credentials."
        )
    )
    parser.add_argument(
        "--config",
        default=CONFIG_DEFAULT_PATH,
        help=f"Path to JSON config file (default: {CONFIG_DEFAULT_PATH})",
    )
    parser.add_argument(
        "--once",
        action="store_true",
        help="Fetch metrics a single time and exit (disables continuous refresh).",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    config = load_config(args.config)
    refresh_minutes = float(config.get("refresh_minutes", 5))
    metrics = config.get("metrics", [])

    token = resolve_token()
    redacted = token[:4] + "***" if len(token) >= 4 else "***"
    print(f"Using session token: {redacted} (not stored)")

    while True:
        data = fetch_metrics(token, metrics)
        print_metrics(data)
        if args.once:
            break
        sleep_seconds = max(refresh_minutes, 0) * 60
        print(f"Next refresh in {refresh_minutes} minute(s)...")
        time.sleep(sleep_seconds)


if __name__ == "__main__":
    main()
