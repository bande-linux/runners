# Unbound Linux CI runners

Self-hosted GitHub Actions runners for the `unbound-linux` organization: five
Docker containers on an Apple Silicon Mac, each registered with the labels
`self-hosted, Linux, ARM64, unbound`. Workflows select them with
`runs-on: [self-hosted, unbound]`.

Jobs build natively on arm64. The image adds the build tools the repositories
need to the official runner image, and the jobs reach the Docker engine through
its socket.

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
- Root runs the jobs, so the image grants root sudo in `/etc/sudoers`; the base
  image ignores `/etc/sudoers.d`.
