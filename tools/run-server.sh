#!/usr/bin/env bash
# Builds the mod and runs a local LAN test server with it.
#
# Usage:
#   tools/run-server.sh [gametype] [map] [+set ...]   # defaults: sd mp_toujane_fix
#   Anything after the map goes to the binary unchanged.
#
# Environment (or the same names in .server/env, a local file git ignores):
#   COD2_GAME_DIR    folder with main/iw_*.iwd (stock files only), required
#   COD2_MAPS_IWD    zPAM map pack, required
#   COD2_SERVER_BIN  dedicated server binary, default ~/OpenCoD2-Plus-Server/bin/cod2rev_lnxded
#   COD2_PORT        UDP port, default 28960
#
# The game folder stays read-only: the mod and every file the server writes
# go to .server/ in this repo.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Machine paths live in .server/env (KEY=value lines); the environment wins over it
if [ -f "$ROOT/.server/env" ]; then
	while IFS='=' read -r key value; do
		case "$key" in
			COD2_GAME_DIR|COD2_MAPS_IWD|COD2_SERVER_BIN|COD2_PORT) [ -n "${!key:-}" ] || export "$key=$value" ;;
		esac
	done < "$ROOT/.server/env"
fi
GAME_DIR="${COD2_GAME_DIR:-}"
SERVER_BIN="${COD2_SERVER_BIN:-$HOME/OpenCoD2-Plus-Server/bin/cod2rev_lnxded}"
MAPS_IWD="${COD2_MAPS_IWD:-}"
PORT="${COD2_PORT:-28960}"
GAMETYPE="${1:-sd}"
MAP="${2:-mp_toujane_fix}"
shift $(( $# < 2 ? $# : 2 ))
HOME_DIR="$ROOT/.server"

die() { echo "ERROR: $*" >&2; exit 1; }

[ -n "$GAME_DIR" ] || die "set COD2_GAME_DIR (or COD2_GAME_DIR=<folder> in .server/env)"
[ -n "$MAPS_IWD" ] || die "set COD2_MAPS_IWD (or COD2_MAPS_IWD=<file> in .server/env)"

[ -x "$SERVER_BIN" ] || die "server binary not found: $SERVER_BIN"
[ -f "$GAME_DIR/main/iw_00.iwd" ] || die "no stock game files in: $GAME_DIR/main"
[ -f "$MAPS_IWD" ] || die "map pack not found: $MAPS_IWD"

mkdir -p "$HOME_DIR/main"
rm -f "$HOME_DIR"/main/zpam[0-9]*.iwd "$HOME_DIR"/main/zpamplus*.iwd
ln -sf "$MAPS_IWD" "$HOME_DIR/main/"
"$ROOT/tools/build-iwd.sh" --out "$HOME_DIR/main/$(sed -n 's|.*level\.pam_folder = "main/\([^"]*\)".*|\1|p' "$ROOT/source/maps/mp/gametypes/global/pam.gsc").iwd"

# 20 characters: CoD2x clients refuse rcon passwords of 24 or more.
RCON_FILE="$HOME_DIR/rcon_password.txt"
[ -s "$RCON_FILE" ] || (umask 077; python3 -c 'import secrets; print(secrets.token_hex(10))' > "$RCON_FILE")

echo "LAN server on port $PORT. rcon password in $RCON_FILE"
exec "$SERVER_BIN" \
	+set fs_basepath "$GAME_DIR" \
	+set fs_homepath "$HOME_DIR" \
	+set fs_game "" \
	+set dedicated 1 \
	+set net_port "$PORT" \
	+set sv_cracked 1 \
	+set sv_punkbuster 0 \
	+set sv_maxclients 20 \
	+set developer 1 \
	+set developer_script 1 \
	+set logfile 2 \
	+set rcon_password "$(cat "$RCON_FILE")" \
	+set g_gametype "$GAMETYPE" \
	"$@" \
	+map "$MAP"
