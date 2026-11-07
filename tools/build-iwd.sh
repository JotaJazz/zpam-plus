#!/usr/bin/env bash
# Builds the mod .iwd from source/.
#
# Usage:
#   tools/build-iwd.sh               # writes <repo>/<name>.iwd
#   tools/build-iwd.sh --out <path>  # writes to the given path
#
# The name comes from level.pam_folder in global/pam.gsc, because the mod
# refuses to run unless the loaded .iwd has exactly that name.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PAM_GSC="$ROOT/source/maps/mp/gametypes/global/pam.gsc"

die() { echo "ERROR: $*" >&2; exit 1; }

NAME="$(sed -n 's|.*level\.pam_folder = "main/\([^"]*\)".*|\1|p' "$PAM_GSC")"
[ -n "$NAME" ] || die "level.pam_folder not found in $PAM_GSC"

OUT="$ROOT/$NAME.iwd"
while [ $# -gt 0 ]; do
	case "$1" in
		--out) OUT="$(realpath -m "${2:?--out needs a path}")"; shift 2 ;;
		-h|--help) sed -n '2,8p' "$0"; exit 0 ;;
		*) die "unknown option: $1" ;;
	esac
done

command -v zip >/dev/null || die "zip is not installed"
# A malformed .str stops the client from loading every .str after it, the stock ones too
python3 "$ROOT/tools/check_str.py" || die "fix the .str files above"
mkdir -p "$(dirname "$OUT")"
rm -f "$OUT"

# -D: no directory entries; -X: no OS-specific metadata in the archive.
(cd "$ROOT/source" && zip -r -q -D -X "$OUT" .)

# The content must sit at the root of the .iwd, or the game finds no script.
zip -T -q "$OUT" >/dev/null || die "invalid archive: $OUT"
unzip -Z1 "$OUT" 'maps/mp/gametypes/global/pam.gsc' >/dev/null 2>&1 || die "wrong layout in $OUT"

echo "OK: $OUT ($(unzip -Z1 "$OUT" | wc -l) files, $(stat -c%s "$OUT") bytes)"
