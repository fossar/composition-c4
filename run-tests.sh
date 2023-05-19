#!/usr/bin/env bash
set -x -o errexit

cd tests

# Nix locks path inputs, preventing us from comitting it.
# Remove a potentially stale lockfile.
# https://github.com/NixOS/nix/issues/3978
rm -f flake.lock

# Work around nix build failing due to git failing with
#     The following paths are ignored by one of your .gitignore files:
#     tests/flake.lock
nix flake lock || true
git add --intent-to-add flake.lock -f

nix build .#grav -L

# Clean up the produced lockfile.
git reset flake.lock
rm flake.lock
