#!/usr/bin/env bash
set -x -o errexit

nix build -L --no-write-lock-file ./tests#composer
nix build -L --no-write-lock-file ./tests#grav
nix build -L --no-write-lock-file ./tests#non-head-rev
nix build -L --no-write-lock-file ./tests#inner-outer-repo
