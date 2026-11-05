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
    with open(os.path.join(root, ".server", "rcon_password.txt"), "rb") as f:
        pw = f.read().strip()
    cmd = " ".join(sys.argv[1:]).encode()
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(2)
    s.sendto(PREFIX + b"rcon " + pw + b" " + cmd, ("127.0.0.1", int(os.environ.get("COD2_PORT", 28960))))
    try:
        data, _ = s.recvfrom(65535)
    except socket.timeout:
        sys.exit("no reply from server")
    sys.stdout.write(data.removeprefix(PREFIX + b"print\n").decode(errors="replace"))


if __name__ == "__main__":
    main()
