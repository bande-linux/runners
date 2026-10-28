#!/bin/bash
# Usage: local-run.sh <repo dir> <command...>
# Runs a command on a copy of a working tree (tracked and untracked files) in a fresh
# runner-image container with KVM, for trying a CI job locally before pushing.
set -euo pipefail

repo=$(cd "$1" && pwd)
shift
name=$(basename "$repo")
export PATH="$HOME/.velox/bin:$PATH"

git -C "$repo" ls-files -z --cached --others --exclude-standard |
    tar -C "$repo" --null -T - -cf - |
    docker run --rm -i --device /dev/kvm \
        -v "local-cargo-$name:/root/.cargo/registry" \
        -v local-rustup:/root/.rustup \
        -v "local-target-$name:/target" \
        -e CARGO_TARGET_DIR=/target \
        --entrypoint bash unbound-runner:local \
        -c 'mkdir -p /work && cd /work && tar xf - && exec bash -lc "$0"' "$*"
