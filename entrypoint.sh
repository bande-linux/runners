#!/bin/bash
set -euo pipefail

cd /home/runner
state=(.runner .credentials .credentials_rsaparams)

if [ -f /state/.runner ]; then
    for f in "${state[@]}"; do cp "/state/$f" .; done
else
    : "${RUNNER_TOKEN:?no registration in /state and RUNNER_TOKEN is unset}"
    ./config.sh --unattended --replace \
        --url "https://github.com/${RUNNER_ORG}" \
        --token "$RUNNER_TOKEN" \
        --name "$RUNNER_NAME" \
        --labels "$RUNNER_LABELS" \
        --work /work
    for f in "${state[@]}"; do cp "$f" /state/; done
fi

exec ./run.sh
