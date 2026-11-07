#!/usr/bin/env python3
"""Start the test server, check that the mod runs cleanly, stop it.

Usage:
  python3 tools/test_server.py [--gametype sd] [--map mp_toujane_fix]
      [--pam-mode comp] [--bots 4] [--seconds 20] [--port 28990]
      [--expect cvar=value ...] [-- +set name value ...]

It runs tools/run-server.sh on a free port, waits for the map, checks that the
binary is a Plus build with sv_plus 123 or later, adds bots, waits, reads back
every --expect cvar, stops the server and scans its console for zPAM errors,
script errors, failed self-tests and a busy port. Exit 0 when all pass.
The console is kept in .server/test_server.log.
"""
import argparse
import os
import re
import signal
import socket
import subprocess
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rcon  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOG = os.path.join(ROOT, ".server", "test_server.log")
MIN_PLUS = 123

# Console lines that mean the run failed
BAD = [
    ("zPAM installation error", re.compile(r"-+ zPAM Errors -+")),
    ("script runtime error", re.compile(r"\*+ script runtime error \*+")),
    ("script compile error", re.compile(r"script compile error", re.I)),
    ("failed self-test", re.compile(r"assert fail")),
    ("port in use", re.compile(r"UDP_OpenSocket: bind")),
]


def cvar_value(reply):
    """Value from an rcon cvar reply ('"x" is: "40^7" default: ...'), without the ^7."""
    m = re.search(r'" is:\s*"(.*?)(\^7)?"', reply or "")
    return m.group(1) if m else None


def scan(log_text):
    """List of (what, line) for every bad console line."""
    found = []
    for line in log_text.splitlines():
        for what, pattern in BAD:
            if pattern.search(line):
                found.append((what, line.strip()))
    return found


def build_line(log_text):
    m = re.search(r"CoD2 MP (\S+) build", log_text)
    return m.group(1) if m else None


def port_free(port):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.bind(("0.0.0.0", port))
        return True
    except OSError:
        return False
    finally:
        s.close()


def read_log():
    with open(LOG, errors="replace") as f:
        return f.read()


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--gametype", default="sd")
    ap.add_argument("--map", default="mp_toujane_fix")
    ap.add_argument("--pam-mode", default="comp")
    ap.add_argument("--bots", type=int, default=4)
    ap.add_argument("--seconds", type=float, default=20)
    ap.add_argument("--port", type=int, default=28990)
    ap.add_argument("--expect", action="append", default=[], metavar="CVAR=VALUE")
    ap.add_argument("extra", nargs="*", help="more +set arguments, after --")
    a = ap.parse_args()

    if not port_free(a.port):
        sys.exit(f"port {a.port} is in use: stop the other server or pass --port")

    env = dict(os.environ, COD2_PORT=str(a.port))
    cmd = [os.path.join(ROOT, "tools", "run-server.sh"), a.gametype, a.map, "+set", "pam_mode", a.pam_mode] + a.extra
    os.makedirs(os.path.dirname(LOG), exist_ok=True)
    errors = []
    with open(LOG, "w") as out:
        proc = subprocess.Popen(cmd, stdout=out, stderr=subprocess.STDOUT, env=env, start_new_session=True)
    try:
        deadline = time.time() + 90
        # Loaded when the console shows the game init and rcon status names the map
        while not ("Game Initialization" in read_log() and "map:" in (rcon.send("status", a.port) or "")):
            if proc.poll() is not None or time.time() > deadline:
                errors.append("the map did not load")
                break
            time.sleep(0.5)

        if not errors:
            build = build_line(read_log())
            if build != "1.3":
                errors.append(f"server build is {build}, a Plus build is 1.3")
            plus = cvar_value(rcon.send("sv_plus", a.port))
            if not plus or not plus.isdigit() or int(plus) < MIN_PLUS:
                errors.append(f"sv_plus is {plus!r}, needs {MIN_PLUS} or later")
            if a.bots:
                rcon.send(f"scr_bots_add {a.bots}", a.port)
            time.sleep(a.seconds)
            for item in a.expect:
                name, _, want = item.partition("=")
                got = cvar_value(rcon.send(name, a.port))
                if got == want:
                    print(f"ok    {name} = {got!r}")
                else:
                    errors.append(f"{name} is {got!r}, want {want!r}")
            if rcon.send("status", a.port) is None:
                errors.append("the server stopped answering")
    finally:
        os.killpg(proc.pid, signal.SIGTERM)
        try:
            proc.wait(10)
        except subprocess.TimeoutExpired:
            os.killpg(proc.pid, signal.SIGKILL)

    for what, line in scan(read_log()):
        errors.append(f"{what}: {line}")

    for e in errors:
        print("FAIL ", e)
    print(("PASS" if not errors else "FAIL") + f"  {a.gametype} {a.map} pam_mode {a.pam_mode} ({LOG})")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
