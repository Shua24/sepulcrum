#!/bin/bash
# deploy.sh - install this repo into /etc/nixos and build it.
#
# The repo is the source of truth; /etc/nixos is a deploy target. This script
# syncs the tree, commits it (a flake cannot see untracked files), and runs
# nixos-rebuild build. It does not activate unless you pass --switch.
#
# Usage:
#   ./deploy.sh            # sync + build
#   ./deploy.sh --switch   # sync + build + activate
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET=/etc/nixos
MODE=build

for argument in "$@"; do
  case "$argument" in
    --switch) MODE=switch ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "unknown argument: $argument" >&2; exit 2 ;;
  esac
done

if [ "$(id -u)" -ne 0 ]; then
  echo "error: run this with sudo - it writes $TARGET" >&2
  exit 1
fi

STAMP="$(date +%Y%m%d-%H%M%S)"

# 1. Back up /etc/nixos once per invocation so a bad deploy is recoverable.
BACKUP="/etc/nixos.backup-$STAMP"
echo "==> backing up $TARGET to $BACKUP"
cp -a "$TARGET" "$BACKUP"

# 2. Sync the tree. hardware-configuration.nix is taken from the live machine
#    when present, because the generated one carries the real UUIDs.
echo "==> syncing repo into $TARGET"
cp "$REPO_DIR/flake.nix" "$TARGET/flake.nix"
cp "$REPO_DIR/configuration.nix" "$TARGET/configuration.nix"
cp "$REPO_DIR/NOTES.md" "$TARGET/NOTES.md"
rm -rf "$TARGET/modules"
cp -a "$REPO_DIR/modules" "$TARGET/modules"
if [ -f "$BACKUP/hardware-configuration.nix" ]; then
  cp "$BACKUP/hardware-configuration.nix" "$TARGET/hardware-configuration.nix"
else
  cp "$REPO_DIR/hardware-configuration.nix" "$TARGET/hardware-configuration.nix"
fi

# 3. Commit. A flake only sees tracked files, so an uncommitted module is
#    invisible to the build and silently does nothing.
echo "==> committing in $TARGET"
if [ ! -d "$TARGET/.git" ]; then
  git -C "$TARGET" init -q
fi
git -C "$TARGET" add -A
if git -C "$TARGET" rev-parse HEAD > /dev/null 2>&1; then
  git -C "$TARGET" commit -q -m "deploy $STAMP" || echo "    (nothing new to commit)"
else
  git -C "$TARGET" -c user.name=nixos -c user.email=root@localhost \
    commit -q -m "deploy $STAMP"
fi

# 4. Resolve inputs if the lock is missing.
if [ ! -f "$TARGET/flake.lock" ]; then
  echo "==> resolving flake inputs"
  nix flake metadata --flake "$TARGET#sepulcrum" > /dev/null
  git -C "$TARGET" add flake.lock
  git -C "$TARGET" commit -q -m "pin flake inputs"
fi

# 5. Build.
echo "==> nixos-rebuild build"
nixos-rebuild build --flake "$TARGET#sepulcrum"

echo
echo "Build succeeded. Previous config: $BACKUP"
if [ "$MODE" = switch ]; then
  echo "==> activating"
  nixos-rebuild switch --flake "$TARGET#sepulcrum"
else
  echo "Activate with:  sudo nixos-rebuild switch --flake $TARGET#sepulcrum"
fi
