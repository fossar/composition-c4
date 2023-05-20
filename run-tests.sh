#!/usr/bin/env bash
set -x -o errexit

nix develop --no-write-lock-file ./tests#python -c black --check --diff src/composer-create-repository.py
nix develop --no-write-lock-file ./tests#python -c mypy --strict src/composer-create-repository.py

nix build -L --no-write-lock-file --extra-experimental-features impure-derivations ./tests#composer-impure
nix build -L --no-write-lock-file --extra-experimental-features impure-derivations ./tests#grav-impure
nix build -L --no-write-lock-file --extra-experimental-features impure-derivations ./tests#non-head-rev-impure

nix build -L --no-write-lock-file ./tests#composer
nix build -L --no-write-lock-file ./tests#grav
nix build -L --no-write-lock-file ./tests#non-head-rev
