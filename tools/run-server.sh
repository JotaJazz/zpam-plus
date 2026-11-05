#!/usr/bin/env bash
# Builds the mod and runs a local LAN test server with it.
#
# Usage:
#   tools/run-server.sh [gametype] [map] [+set ...]   # defaults: sd mp_toujane_fix
#   Anything after the map goes to the binary unchanged.
#
# Environment:
#   COD2_GAME_DIR    folder with main/iw_*.iwd (stock files only)
#   COD2_SERVER_BIN  dedicated server binary
#   COD2_MAPS_IWD    zPAM map pack
#   COD2_PORT        UDP port, default 28960
#
# The game folder stays read-only: the mod and every file the server writes
# go to .server/ in this repo.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GAME_DIR="${COD2_GAME_DIR:-/mnt/e/Servers/COD2}"
SERVER_BIN="${COD2_SERVER_BIN:-$HOME/CoD2rev_Server/bin/cod2rev_lnxded}"
MAPS_IWD="${COD2_MAPS_IWD:-/mnt/e/Servers/COD2-MAPAS/zpam_maps_v6.iwd}"
PORT="${COD2_PORT:-28960}"
GAMETYPE="${1:-sd}"
MAP="${2:-mp_toujane_fix}"
shift $(( $# < 2 ? $# : 2 ))
HOME_DIR="$ROOT/.server"

die() { echo "ERROR: $*" >&2; exit 1; }

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
