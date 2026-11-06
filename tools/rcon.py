#!/usr/bin/env python3
"""Send one rcon command to the local test server and print the reply.

Usage: python3 tools/rcon.py <command...>
Port from COD2_PORT (default 28960), password from .server/rcon_password.txt.
"""
import os
import socket
import sys

PREFIX = b"\xff\xff\xff\xff"


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    try:
        with open(os.path.join(root, ".server", "rcon_password.txt"), "rb") as f:
            pw = f.read().strip()
    except FileNotFoundError:
        sys.exit("start tools/run-server.sh first")
    cmd = " ".join(sys.argv[1:]).encode()
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(2)
    s.sendto(PREFIX + b"rcon " + pw + b" " + cmd, ("127.0.0.1", int(os.environ.get("COD2_PORT", 28960))))
    head = PREFIX + b"print\n"
    try:
        out = s.recvfrom(65535)[0].removeprefix(head)
    except socket.timeout:
        sys.exit("no reply from server")
    s.settimeout(0.3)
    try:
        while True:
            out += s.recvfrom(65535)[0].removeprefix(head)
    except socket.timeout:
        pass
    sys.stdout.write(out.decode(errors="replace"))


if __name__ == "__main__":
    main()
