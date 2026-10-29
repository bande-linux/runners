# Unbound Linux CI runners

Self-hosted GitHub Actions runners for the `unbound-linux` organization: eight
Docker containers on an Apple Silicon Mac, each registered with the labels
`self-hosted, Linux, ARM64, unbound`. Workflows select them with
`runs-on: [self-hosted, unbound]`.

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
rm .env
```

The registration token needs an organization admin and expires after an hour.
Each runner registers once and keeps its registration in its `state-N` volume;
restarts and image rebuilds reuse it.

To update the image after changing the Dockerfile:

```sh
docker compose up -d --build
```

## Trying a job locally

On a Mac with Velox running and nested virtualization enabled, build the image once with
`docker build -t unbound-runner:local .`, then run a command on a copy of a working tree:

```sh
./local-run.sh ../desktop "cargo test --workspace"
```

The copy includes untracked files; caches for crates, toolchains and build output persist in
named volumes between runs.

## Limits

- Jobs cannot use `container:`: the runner's work directory lives in a volume
  of the runner container, which a job container cannot mount.
- The runners get `/dev/kvm` for VM tests, so the Docker engine must have
  nested virtualization enabled; without it the containers fail to start.
- Root runs the jobs; `sudo` is installed so workflow steps that call it work.
- `actions/setup-python` and similar actions download builds made for GitHub's
  Ubuntu images and find none for Debian; use the image's `python3` (3.13) in a
  venv instead.
- The previous Ubuntu image stays tagged `unbound-runner:2.338.0`; pointing
  `compose.yaml` back at it and running `docker compose up -d` rolls back.
