#!/usr/bin/env bash
set -x -o errexit

cd tests

# Work around nix build failing due to git failing with
#     The following paths are ignored by one of your .gitignore files:
#     tests/flake.lock
nix flake lock || true
git add --intent-to-add flake.lock -f

nix build .#grav -L
