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
# Overridable so the script can be rehearsed against a scratch copy without
# touching the real /etc/nixos.
TARGET="${DEPLOY_TARGET:-/etc/nixos}"
MODE=build
# Set DEPLOY_SKIP_ROOT_CHECK=1 to rehearse as a normal user.
SKIP_ROOT_CHECK="${DEPLOY_SKIP_ROOT_CHECK:-0}"

for argument in "$@"; do
  case "$argument" in
  --switch) MODE=switch ;;
  -h | --help)
    sed -n '2,12p' "$0"
    exit 0
    ;;
  *)
    echo "unknown argument: $argument" >&2
    exit 2
    ;;
  esac
done

if [ "$SKIP_ROOT_CHECK" != 1 ] && [ "$(id -u)" -ne 0 ]; then
  echo "error: run this with sudo - it writes $TARGET" >&2
  exit 1
fi

# This repo deliberately does NOT contain hardware-configuration.nix (it carries
# the machine's partition UUIDs). Without one the build produces a system with
# no fileSystems and will not boot, so refuse rather than ship that.
if [ ! -f "$TARGET/hardware-configuration.nix" ]; then
  echo "error: $TARGET/hardware-configuration.nix is missing." >&2
  echo "       That file is generated per machine and is not in this repo." >&2
  echo "       On an installed system it should already exist. If not, run:" >&2
  echo "         sudo nixos-generate-config" >&2
  exit 1
fi

STAMP="$(date +%Y%m%d-%H%M%S)"

# 1. Back up /etc/nixos once per invocation so a bad deploy is recoverable.
BACKUP="${TARGET}.backup-$STAMP"
echo "==> backing up $TARGET to $BACKUP"
cp -a "$TARGET" "$BACKUP"

# 2. Sync the tree. hardware-configuration.nix is taken from the live machine
#    when present, because the generated one carries the real UUIDs.
echo "==> syncing repo into $TARGET"
cp "$REPO_DIR/flake.nix" "$TARGET/flake.nix"
cp "$REPO_DIR/configuration.nix" "$TARGET/configuration.nix"
# NOTES.md stays in the repo. /etc/nixos holds only what the build needs.
rm -rf "$TARGET/modules"
cp -a "$REPO_DIR/modules" "$TARGET/modules"
# hardware-configuration.nix is intentionally NOT copied: the live one already in
# $TARGET is the truth (real UUIDs for this machine). It was backed up above.
if [ -f "$BACKUP/hardware-configuration.nix" ]; then
  cp "$BACKUP/hardware-configuration.nix" "$TARGET/hardware-configuration.nix"
fi

# 3. Resolve inputs if the lock is missing.
#
# There is deliberately NO git in this script. Building with `path:$TARGET`
# (step 4) makes the flake read the directory directly, so the target needs no
# repository, no commits and no identity. That is what keeps this working under
# sudo, where git does not read the invoking user's ~/.gitconfig.
if [ ! -f "$TARGET/flake.lock" ]; then
  echo "==> resolving flake inputs"
  nix flake metadata "path:$TARGET" >/dev/null
fi

# 5. Build.
#
# `path:$TARGET` rather than `$TARGET` is deliberate and load-bearing. A plain
# path reference to a git repo copies only TRACKED files, and
# hardware-configuration.nix is gitignored on purpose (it carries this machine's
# partition UUIDs). Under the git form the file is invisible, the conditional
# import in configuration.nix evaluates to nothing, and the build dies with
# "The 'fileSystems' option does not specify your root file system".
# `path:` reads the directory directly, so the generated file is seen and the
# rest of the tree still comes from the same checkout.
FLAKE_REF="path:$TARGET#sepulcrum"
echo "==> nixos-rebuild build"
nixos-rebuild build --flake "$FLAKE_REF"

echo
echo "Build succeeded. Previous config: $BACKUP"
if [ "$MODE" = switch ]; then
  echo "==> activating"
  nixos-rebuild switch --flake "$FLAKE_REF"
else
  echo "Activate with:  sudo nixos-rebuild switch --flake $FLAKE_REF"
fi
