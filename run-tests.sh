#!/usr/bin/env bash
set -x -o errexit

cd tests/grav
nix build .#grav -L
