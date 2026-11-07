#!/usr/bin/env python3
"""Check the mod's localizedstrings/*.str before they go into the iwd.

Usage: python3 tools/check_str.py [file.str ...]   (default: source/localizedstrings/*.str)

The client stops loading every .str after a malformed one, the stock files
included, and says nothing unless loc_warnings is 1. So this refuses a file
that is not Windows-1252 (or looks like UTF-8), has a line over 16 KB or a text over 4096 bytes,
has an entry whose first language is not LANG_ENGLISH (a later English line
would hide the translation), a LANG_ line outside an entry, a duplicate
REFERENCE, an unquoted text, a bad &&N argument, or no ENDMARKER.
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LINE_MAX = 16 * 1024
TEXT_MAX = 4096
LANG = re.compile(r'^LANG_(\w+)\s+"(.*)"\s*$')


def check(name, data):
    """List of error strings for the bytes of one .str file."""
    errors = []
    # UTF-8 bytes are also valid Windows-1252, so look for UTF-8 first: accented
    # Windows-1252 text (é is the single byte 0xE9) is almost never valid UTF-8
    if any(b > 127 for b in data):
        try:
            data.decode("utf-8")
            return [f"{name}: looks like UTF-8; save it as Windows-1252 (the game would show \"Ã©\" for \"é\")"]
        except UnicodeDecodeError:
            pass
    try:
        text = data.decode("cp1252")
    except UnicodeDecodeError as e:
        return [f"{name}: not Windows-1252 ({e})"]
    refs = set()
    ref = None
    langs = []
    ended = False
    for n, line in enumerate(text.split("\n"), 1):
        where = f"{name}:{n}"
        line = line.rstrip("\r")
        if len(line.encode("cp1252")) >= LINE_MAX:
            errors.append(f"{where}: line over 16 KB")
        s = line.strip()
        if not s or s.startswith("//") or s.split()[0] in ("VERSION", "CONFIG", "FILENOTES", "NOTES", "FLAGS"):
            continue
        if s == "ENDMARKER":
            ended = True
            continue
        if s.startswith("REFERENCE"):
            parts = s.split()
            if len(parts) != 2 or not re.fullmatch(r"[A-Z0-9_]+", parts[1]):
                errors.append(f"{where}: bad REFERENCE")
                continue
            if parts[1] in refs:
                errors.append(f"{where}: duplicate REFERENCE {parts[1]}")
            refs.add(parts[1])
            ref, langs = parts[1], []
            continue
        if s.startswith("LANG_"):
            m = LANG.match(s)
            if not m:
                errors.append(f"{where}: text must be one quoted string")
                continue
            if ref is None:
                errors.append(f"{where}: LANG_ line outside a REFERENCE")
                continue
            if not langs and m.group(1) != "ENGLISH":
                errors.append(f"{where}: {ref} must start with LANG_ENGLISH")
            if m.group(1) in langs:
                errors.append(f"{where}: {ref} has LANG_{m.group(1)} twice")
            langs.append(m.group(1))
            if len(m.group(2).encode("cp1252")) > TEXT_MAX:
                errors.append(f"{where}: text over {TEXT_MAX} bytes")
            # As WebSE_ValidateFormatArgs: "&&" + a digit 1-9, each at most once
            args = re.findall(r"&&(.?)", m.group(2))
            if any(a < "1" or a > "9" for a in args) or len(args) != len(set(args)):
                errors.append(f"{where}: bad &&N argument (1-9, each once)")
            continue
        errors.append(f"{where}: unexpected line")
    if not ended:
        errors.append(f"{name}: no ENDMARKER")
    return errors


def main():
    files = sys.argv[1:] or sorted(glob.glob(os.path.join(ROOT, "source", "localizedstrings", "*.str")))
    errors = []
    for f in files:
        with open(f, "rb") as fh:
            errors += check(os.path.relpath(f, ROOT), fh.read())
    for e in errors:
        print("ERROR:", e, file=sys.stderr)
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
