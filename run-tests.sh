#!/usr/bin/env bash
set -x -o errexit

cd tests/grav
nix flake update --override-input c4 ../..
nix build .#grav -L
