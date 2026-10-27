FROM ghcr.io/actions/actions-runner:2.338.0

USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        7zip bc bison build-essential ca-certificates clang cpio curl \
        device-tree-compiler flex git gnupg jq kmod libarchive-tools libelf-dev \
        libssl-dev lld llvm python3 python3-pip python3-venv qemu-efi-aarch64 qemu-system-arm \
        qemu-utils cloud-image-utils rsync sccache wget xz-utils zstd \
    && curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --dearmor -o /usr/share/keyrings/llvm.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/llvm.gpg] http://apt.llvm.org/noble/ llvm-toolchain-noble-20 main" \
        > /etc/apt/sources.list.d/llvm-20.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends clang-format-20 \
    && rm -rf /var/lib/apt/lists/*

ENV PATH=/root/.cargo/bin:$PATH
RUN curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal --component rustfmt,clippy \
        --target aarch64-unknown-none-softfloat,aarch64-unknown-linux-musl

RUN echo "root ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY entrypoint.sh /entrypoint.sh
RUN chmod 0755 /entrypoint.sh

ENV RUNNER_ALLOW_RUNASROOT=1
ENTRYPOINT ["/entrypoint.sh"]
