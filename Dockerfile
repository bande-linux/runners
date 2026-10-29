FROM debian:trixie

ARG RUNNER_VERSION=2.338.0
ARG RUNNER_SHA256=628b4a7258487b80c1d3c221095a7ded349f5ae0175fd3dfab708d07428f041b

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        7zip bc bison build-essential ca-certificates clang cpio curl \
        device-tree-compiler flex git gnupg jq kmod libarchive-tools libelf-dev \
        libicu76 libkrb5-3 libssl-dev lld llvm python3 python3-pip python3-venv qemu-efi-aarch64 \
        qemu-system-arm qemu-utils cloud-image-utils rsync sccache sudo tzdata unzip wget xz-utils \
        zlib1g zstd \
    && curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor -o /usr/share/keyrings/llvm.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/llvm.gpg] http://apt.llvm.org/trixie/ llvm-toolchain-trixie-20 main" \
        > /etc/apt/sources.list.d/llvm-20.list \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/debian trixie stable" \
        > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends clang-format-20 docker-ce-cli docker-buildx-plugin \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /home/runner
RUN curl -fsSLo runner.tar.gz \
        "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz" \
    && echo "${RUNNER_SHA256}  runner.tar.gz" | sha256sum -c - \
    && tar xzf runner.tar.gz \
    && rm runner.tar.gz

ENV PATH=/root/.cargo/bin:$PATH
RUN curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal --component rustfmt,clippy \
        --target aarch64-unknown-none-softfloat,aarch64-unknown-linux-musl

COPY entrypoint.sh /entrypoint.sh
COPY job-started.sh /usr/local/bin/job-started.sh
RUN chmod 0755 /entrypoint.sh

ENV ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=1
ENV RUNNER_MANUALLY_TRAP_SIG=1
ENV RUNNER_ALLOW_RUNASROOT=1
ENTRYPOINT ["/entrypoint.sh"]
