#!/usr/bin/env bash
set -x -o errexit

nix build -L --no-write-lock-file ./tests#grav
