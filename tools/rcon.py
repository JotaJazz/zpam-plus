#!/usr/bin/env python3
"""Send one rcon command to the local test server and print the reply.

Usage: python3 tools/rcon.py <command...>
Port from COD2_PORT (default 28960), password from .server/rcon_password.txt.
"""
import os
import socket
import sys

PREFIX = b"\xff\xff\xff\xff"


def send(cmd, port=None):
    """Send one rcon command and return the reply text; None if the server does not answer."""
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    with open(os.path.join(root, ".server", "rcon_password.txt"), "rb") as f:
        pw = f.read().strip()
    port = port or int(os.environ.get("COD2_PORT", 28960))
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.settimeout(2)
    s.sendto(PREFIX + b"rcon " + pw + b" " + cmd.encode(), ("127.0.0.1", port))
    head = PREFIX + b"print\n"
    try:
        out = s.recvfrom(65535)[0].removeprefix(head)
    except socket.timeout:
        return None
    s.settimeout(0.3)
    try:
        while True:
            out += s.recvfrom(65535)[0].removeprefix(head)
    except socket.timeout:
        pass
    return out.decode(errors="replace")


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    try:
        out = send(" ".join(sys.argv[1:]))
    except FileNotFoundError:
        sys.exit("start tools/run-server.sh first")
    if out is None:
        sys.exit("no reply from server")
    sys.stdout.write(out)


if __name__ == "__main__":
    main()
