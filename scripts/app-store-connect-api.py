#!/usr/bin/env python3
"""Make an authenticated App Store Connect API request.

Run with PyJWT available, for example:
    uv run --with pyjwt --with cryptography python scripts/app-store-connect-api.py GET /v1/apps

Credentials are read from ASC_KEY_ID, ASC_ISSUER_ID, and ASC_KEY_PATH.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

import jwt


API_ROOT = "https://api.appstoreconnect.apple.com"


def required_environment(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        raise SystemExit(f"Missing required environment variable: {name}")
    return value


def make_token() -> str:
    key_id = required_environment("ASC_KEY_ID")
    issuer_id = required_environment("ASC_ISSUER_ID")
    private_key = Path(required_environment("ASC_KEY_PATH")).read_text(encoding="utf-8")
    now = int(time.time())
    return jwt.encode(
        {"iss": issuer_id, "iat": now, "exp": now + 900, "aud": "appstoreconnect-v1"},
        private_key,
        algorithm="ES256",
        headers={"kid": key_id, "typ": "JWT"},
    )


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("method", choices=("GET", "POST", "PATCH", "DELETE"))
    parser.add_argument("path", help="API path beginning with /v1/")
    body_group = parser.add_mutually_exclusive_group()
    body_group.add_argument("--data", help="JSON request body")
    body_group.add_argument("--data-file", type=Path, help="Path to a JSON request body")
    return parser.parse_args()


def main() -> None:
    arguments = parse_arguments()
    if not arguments.path.startswith("/v1/"):
        raise SystemExit("API path must begin with /v1/")

    body = arguments.data
    if arguments.data_file:
        body = arguments.data_file.read_text(encoding="utf-8")

    encoded_body = body.encode("utf-8") if body is not None else None
    request = urllib.request.Request(
        f"{API_ROOT}{arguments.path}",
        data=encoded_body,
        method=arguments.method,
        headers={
            "Authorization": f"Bearer {make_token()}",
            "Content-Type": "application/json",
        },
    )

    try:
        with urllib.request.urlopen(request) as response:
            payload = response.read().decode("utf-8")
    except urllib.error.HTTPError as error:
        print(error.read().decode("utf-8"), file=sys.stderr)
        raise SystemExit(error.code) from error

    if payload:
        parsed = json.loads(payload)
        print(json.dumps(parsed, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
