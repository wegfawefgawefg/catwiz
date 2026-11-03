#!/usr/bin/env python3
"""Takes Catwiz's anonymous play records (Tisple's web/telemetry.js) and appends them to a JSONL
file, one post a line with the server's time. Runs on the dev VPS behind nginx
(https://45.77.123.14/catwiz-telemetry, tools/telemetry/nginx.conf, catwiz-telemetry.service).

    receiver.py [--port 8795] [--dir $STATE_DIRECTORY] [--origin URL]...

POST /catwiz-telemetry          a post from the player, text/plain JSON: 204, or 4xx for junk
GET  /catwiz-telemetry/health   {"ok": true}

Only posts from the player's two homes are taken (the Pages site and the phone server: Origin);
each is checked field by field and size by size, and posts are rate limited, overall and a
session. Nothing about the sender is kept: no address (nginx keeps no log for it either), no
headers; the line is the post as sent, plus "at" (the server's time) and "via" (which origin).
"""

import argparse
import json
import os
import re
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ORIGINS = {"https://wegfawefgawefg.github.io": "pages", "http://100.77.88.90:8650": "phone"}
PATH = "/catwiz-telemetry"
BODY_MOST = 16 * 1024
FILE_MOST = 512 * 1024 * 1024
RECS_MOST = 60
POSTS_A_MINUTE = 600         # everyone
SESSION_POSTS_A_MINUTE = 20  # one session (the player posts every 20 s, and as it hides)

NAME = re.compile(r"[a-z][a-z0-9_]{0,23}")
GAME = re.compile(r"catwiz[A-Za-z0-9_-]{0,34}")
BUILD = re.compile(r"[A-Za-z0-9 :._-]{0,40}")
SID = re.compile(r"[0-9a-f]{16}")


def is_int(x, low, high):
    return type(x) is int and low <= x <= high


def is_number(x, low, high):
    return type(x) in (int, float) and low <= x <= high


def check_values(values):
    if not isinstance(values, dict) or len(values) > 40:
        raise ValueError("values")
    for key, value in values.items():
        if not NAME.fullmatch(key):
            raise ValueError("value name")
        if isinstance(value, list):
            if len(value) > 32 or not all(is_int(x, -65536, 65536) for x in value):
                raise ValueError("value list")
        elif not is_int(value, -65536, 65536):
            raise ValueError("value")


def check(post):
    """the post as it should be, else ValueError"""
    if not isinstance(post, dict) or set(post) != {"game", "build", "where", "sid", "load", "seq", "recs"}:
        raise ValueError("keys")
    if not isinstance(post["game"], str) or not GAME.fullmatch(post["game"]):
        raise ValueError("game")
    if not isinstance(post["build"], str) or not BUILD.fullmatch(post["build"]):
        raise ValueError("build")
    if post["where"] not in ("pages", "phone"):
        raise ValueError("where")
    if not isinstance(post["sid"], str) or not SID.fullmatch(post["sid"]):
        raise ValueError("sid")
    if not is_int(post["load"], 1, 100000) or not is_int(post["seq"], 1, 1000000):
        raise ValueError("load, seq")
    recs = post["recs"]
    if not isinstance(recs, list) or not 1 <= len(recs) <= RECS_MOST:
        raise ValueError("recs")
    for rec in recs:
        if not isinstance(rec, dict) or not {"e", "t", "dt", "gt"} <= set(rec) <= {"e", "t", "dt", "gt", "v", "pre", "entry"}:
            raise ValueError("rec keys")
        if not isinstance(rec["e"], str) or not NAME.fullmatch(rec["e"]):
            raise ValueError("rec name")
        for key in ("t", "dt", "gt"):
            if not is_number(rec[key], -1e7, 1e7):
                raise ValueError("rec time")
        for key in ("v", "pre", "entry"):
            if key in rec:
                check_values(rec[key])
    return post


class Limits:
    """posts a minute, overall and by session; forgets each minute"""

    def __init__(self):
        self.lock = threading.Lock()
        self.minute = 0
        self.total = 0
        self.sessions = {}

    def allow(self, sid):
        with self.lock:
            now = int(time.time() // 60)
            if now != self.minute:
                self.minute = now
                self.total = 0
                self.sessions = {}
            if self.total >= POSTS_A_MINUTE or self.sessions.get(sid, 0) >= SESSION_POSTS_A_MINUTE:
                return False
            self.total += 1
            self.sessions[sid] = self.sessions.get(sid, 0) + 1
            return True


def make_handler(path, origins):
    limits = Limits()
    write_lock = threading.Lock()

    class Handler(BaseHTTPRequestHandler):
        server_version = "catwiz-telemetry"
        sys_version = ""

        def log_message(self, format, *args):
            pass  # no request log: nothing about who sent what

        def reply(self, code, body=b"", origin=None):
            self.send_response(code)
            if origin:
                self.send_header("Access-Control-Allow-Origin", origin)
                self.send_header("Vary", "Origin")
            if body:
                self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            if body:
                self.wfile.write(body)

        def do_GET(self):
            if self.path == PATH + "/health":
                self.reply(200, b'{"ok": true}\n')
                return
            self.reply(404)

        def do_OPTIONS(self):
            origin = self.headers.get("Origin", "")
            if self.path != PATH or origin not in origins:
                self.reply(403)
                return
            self.send_response(204)
            self.send_header("Access-Control-Allow-Origin", origin)
            self.send_header("Access-Control-Allow-Methods", "POST")
            self.send_header("Access-Control-Allow-Headers", "Content-Type")
            self.send_header("Access-Control-Max-Age", "86400")
            self.send_header("Vary", "Origin")
            self.send_header("Content-Length", "0")
            self.end_headers()

        def do_POST(self):
            origin = self.headers.get("Origin", "")
            if self.path != PATH:
                self.reply(404)
                return
            if origin not in origins:
                self.reply(403)
                return
            try:
                size = int(self.headers.get("Content-Length", "0"))
            except ValueError:
                size = -1
            if not 0 < size <= BODY_MOST:
                self.reply(413 if size > BODY_MOST else 400, origin=origin)
                return
            try:
                post = check(json.loads(self.rfile.read(size)))
            except (ValueError, UnicodeDecodeError, RecursionError):
                self.reply(400, origin=origin)
                return
            if not limits.allow(post["sid"]):
                self.reply(429, origin=origin)
                return
            line = json.dumps({"at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                               "via": origins[origin], **post}, separators=(",", ":"))
            with write_lock:
                try:
                    if os.path.exists(path) and os.path.getsize(path) > FILE_MOST:
                        self.reply(507, origin=origin)
                        return
                    with open(path, "a") as f:
                        f.write(line + "\n")
                except OSError:
                    self.reply(500, origin=origin)
                    return
            self.reply(204, origin=origin)

    return Handler


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, default=8795)
    parser.add_argument("--bind", default="127.0.0.1")
    parser.add_argument("--dir", default=os.environ.get("STATE_DIRECTORY", "."))
    parser.add_argument("--origin", action="append", default=[],
                        help="another origin to take posts from (a test page), as URL=label")
    args = parser.parse_args()
    origins = dict(ORIGINS)
    for extra in args.origin:
        url, _, label = extra.partition("=")
        origins[url] = label or "test"
    os.makedirs(args.dir, exist_ok=True)
    path = os.path.join(args.dir, "events.jsonl")
    server = ThreadingHTTPServer((args.bind, args.port), make_handler(path, origins))
    server.daemon_threads = True
    server.serve_forever()


if __name__ == "__main__":
    main()
