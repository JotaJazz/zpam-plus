#!/usr/bin/env python3
"""Start the test server, check that the mod runs cleanly, stop it.

Usage:
  python3 tools/test_server.py [--gametype sd] [--map mp_toujane_fix]
      [--pam-mode comp] [--bots 4] [--seconds 20] [--port 28990]
      [--expect cvar=value ...] [--duel weapon,distance,head|torso|neck[,kill|damage|lo-hi] ...]
      [--rcon command ...] [--log regex ...] [-- +set name value ...]

It runs tools/run-server.sh on a free port, waits for the map, checks that the
binary is a Plus build with sv_plus 123 or later, adds bots, waits, reads back
every --expect cvar, runs every --duel (one bot shoots another once; expect
"kill" or the damage), stops the server and scans its console for zPAM errors,
script errors, failed self-tests and a busy port. Exit 0 when all pass.
Duels need a live round: --pam-mode pub -- +set scr_sd_strat_time 0
+set scr_bots_freeze 0.
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


def duel_result(line):
    """Fields of a 'DUEL done k=v ...' console line, or None."""
    if "DUEL done" not in line:
        return None
    return dict(kv.split("=", 1) for kv in line.split("DUEL done", 1)[1].split() if "=" in kv)


def duel_ok(result, expect):
    """expect is "kill", the damage the target took, or a damage range "lo-hi"."""
    if expect == "kill":
        return result.get("alive") == "0"
    lo, _, hi = expect.partition("-")
    damage = 100 - int(result.get("health", -1))
    return result.get("alive") == "1" and int(lo) <= damage <= int(hi or lo)


def run_duel(spec, port):
    """Run one duel, retrying while no two live bots exist. Returns (result dict or None, message)."""
    weapon, dist, aim = spec.split(",")[:3]
    for _ in range(20):
        before = read_log().count("DUEL ")
        rcon.send(f'set dev_duel "{weapon} {dist} {aim}"', port)
        deadline = time.time() + 10
        while time.time() < deadline:
            new = [l for l in read_log().splitlines() if "DUEL " in l][before:]
            if new:
                break
            time.sleep(0.3)
        else:
            return None, "no DUEL reply"
        result = duel_result(new[0])
        if result is not None:
            return result, new[0].strip()
        if "two live bots" not in new[0] and "round not live" not in new[0]:
            return None, new[0].strip()
        time.sleep(2)  # between rounds: wait for the round and the bots
    return None, "no two live bots"


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


def read_games(path, start):
    """games_mp.log written since this run started."""
    if not os.path.exists(path):
        return ""
    with open(path, errors="replace") as f:
        f.seek(start)
        return f.read()


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
    ap.add_argument("--duel", action="append", default=[], metavar="WEAPON,DIST,head|torso|neck[,EXPECT]")
    ap.add_argument("--rcon", action="append", default=[], metavar="COMMAND", help="sent in order once the map loads; \"sleep N\" waits N seconds")
    ap.add_argument("--log", action="append", default=[], metavar="REGEX", help="games_mp.log of this run must match, within 30 s")
    ap.add_argument("extra", nargs="*", help="more +set arguments, after --")
    a = ap.parse_args()

    if not port_free(a.port):
        sys.exit(f"port {a.port} is in use: stop the other server or pass --port")

    env = dict(os.environ, COD2_PORT=str(a.port))
    # g_logSync 1: games_mp.log is written at once, not buffered, so --log sees new lines
    cmd = [os.path.join(ROOT, "tools", "run-server.sh"), a.gametype, a.map, "+set", "pam_mode", a.pam_mode,
           "+set", "g_logSync", "1"] + a.extra
    os.makedirs(os.path.dirname(LOG), exist_ok=True)
    games_log = os.path.join(ROOT, ".server", "main", "games_mp.log")
    games_start = os.path.getsize(games_log) if os.path.exists(games_log) else 0
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
            for command in a.rcon:
                if command.startswith("sleep "):  # not sent: lets a map_restart finish
                    time.sleep(float(command.split()[1]))
                else:
                    rcon.send(command, a.port)
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
            for spec in a.duel:
                result, msg = run_duel(spec, a.port)
                parts = spec.split(",")
                if result is None:
                    errors.append(f"duel {spec}: {msg}")
                elif len(parts) > 3 and not duel_ok(result, parts[3]):
                    errors.append(f"duel {spec}: {msg}")
                else:
                    print(f"ok    duel {spec}: {msg.split('DUEL done', 1)[-1].strip()}")
            # Wait up to 30 s for each --log line, with the server still running
            for pattern in a.log:
                deadline = time.time() + 30
                while not re.search(pattern, read_games(games_log, games_start), re.M):
                    if time.time() > deadline or proc.poll() is not None:
                        errors.append(f"games_mp.log has no line matching {pattern!r}")
                        break
                    time.sleep(0.5)
            if rcon.send("status", a.port) is None:
                errors.append("the server stopped answering")
    finally:
        if proc.poll() is None:
            os.killpg(proc.pid, signal.SIGTERM)
            try:
                proc.wait(10)
            except subprocess.TimeoutExpired:
                os.killpg(proc.pid, signal.SIGKILL)
        else:
            # A script error with developer 1 shuts the server down
            errors.append("the server exited before the check ended")

    for what, line in scan(read_log()):
        errors.append(f"{what}: {line}")

    for e in errors:
        print("FAIL ", e)
    print(("PASS" if not errors else "FAIL") + f"  {a.gametype} {a.map} pam_mode {a.pam_mode} ({LOG})")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
