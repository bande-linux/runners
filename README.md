# Unbound Linux CI runners

Self-hosted GitHub Actions runners for the `unbound-linux` organization, on two
Apple Silicon Macs: the M4 Mac mini (`unbound-runner-1..3`, `unbound-runner-kvm`)
and the laptop (`laptop-runner-1..3`, `laptop-runner-kvm`). Each Mac runs four
Docker containers from the same `compose.yaml`. Three are registered with the labels
`self-hosted, Linux, ARM64, unbound` and run builds and tests; workflows select
them with `runs-on: [self-hosted, unbound]`. The fourth, labelled `unbound-kvm`,
is the only one with `/dev/kvm` and runs the jobs that boot a KVM guest, so at
most one guest runs per Mac; those jobs use `runs-on: [self-hosted, unbound-kvm]`.
GitHub hands each job to any free runner with matching labels, so both Macs share
the queue, and with the laptop off everything runs on the mini.

Jobs build natively on arm64 on Debian 13 (trixie), the release the desktop's
packages target. The image is `debian:trixie` with the GitHub Actions runner
(version and checksum pinned in the `Dockerfile`), the Docker CLI from Docker's
Debian repository and the build tools the repositories need; the jobs reach the
Docker engine through its socket. GitHub offers no Debian images of its own
runner, so this image replaces `ghcr.io/actions/actions-runner` (Ubuntu).

## Setup

On the Mac, with Docker running and the repository cloned:

```sh
gh api -X POST orgs/unbound-linux/actions/runners/registration-token \
    --jq '"RUNNER_TOKEN=" + .token' > .env
docker compose up -d --build
```

Then remove the `RUNNER_TOKEN` line from `.env`. On every Mac but the mini, also put
`RUNNER_HOST=<machine>` in `.env` (the laptop has `RUNNER_HOST=laptop`); it names the
runners and their hostnames, which default to `unbound-runner-N`.

The registration token needs an organization admin and expires after an hour.
Each runner registers once and keeps its registration in its `state-N` volume;
restarts and image rebuilds reuse it.

To update the image after changing the Dockerfile:

```sh
docker compose up -d --build
```

## Trying a job locally

Push the branch: its jobs run on these runners, the laptop's included, so CI is how changes
are tested. `local-run.sh` runs a command on a copy of a working tree in the runner image
(build it once with `docker build -t unbound-runner:local .`), for debugging a job by hand:

```sh
./local-run.sh ../desktop "cargo test --workspace"
```

It mounts neither the Docker socket nor a guest image cache, so `ci/vm` does not run through
it.

## Limits

- Jobs cannot use `container:`: the runner's work directory lives in a volume
  of the runner container, which a job container cannot mount.
- The `unbound-kvm` runner gets `/dev/kvm` for VM tests, so the Docker engine
  must have nested virtualization enabled; without it that container fails to start.
- Root runs the jobs; `sudo` is installed so workflow steps that call it work.
- `actions/setup-python` and similar actions download builds made for GitHub's
  Ubuntu images and find none for Debian; use the image's `python3` (3.13) in a
  venv instead.
- The previous Ubuntu image stays tagged `unbound-runner:2.338.0`; pointing
  `compose.yaml` back at it and running `docker compose up -d` rolls back.
