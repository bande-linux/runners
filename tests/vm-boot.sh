#!/bin/bash
# Usage: vm-boot.sh <disk.qcow2>
# Boots the disk under QEMU/KVM with a cloud-init seed and passes once the
# serial console shows a login prompt and the marker written by cloud-init.
set -euo pipefail

disk=$(realpath "$1")
work=$(mktemp -d)
qpid=
trap '[ -n "$qpid" ] && kill "$qpid" 2>/dev/null; rm -rf "$work"' EXIT
cd "$work"

qemu-img create -q -f qcow2 -F qcow2 -b "$disk" overlay.qcow2

cat > user-data <<'EOF'
#cloud-config
runcmd:
  - [sh, -c, 'echo UNBOUND-VM-READY > /dev/ttyAMA0']
EOF
echo "instance-id: vm-boot" > meta-data
cloud-localds seed.img user-data meta-data

# Under nested KVM on Apple Silicon, MSIs routed through the emulated GIC ITS
# get lost and the guest stalls once systemd starts.
qemu-system-aarch64 \
    -machine virt,gic-version=max,its=off -accel kvm -cpu host -smp 2 -m 2048 \
    -bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd \
    -drive if=virtio,file=overlay.qcow2 \
    -drive if=virtio,format=raw,file=seed.img \
    -netdev user,id=net0 -device virtio-net-pci,netdev=net0,romfile= \
    -display none -monitor none -serial file:serial.log &
qpid=$!

start=$SECONDS
until grep -q "login:" serial.log 2>/dev/null && grep -q "UNBOUND-VM-READY" serial.log; do
    if ! kill -0 "$qpid" 2>/dev/null; then
        echo "QEMU exited before the guest was ready"
        cat serial.log
        exit 1
    fi
    if [ $((SECONDS - start)) -gt 300 ]; then
        echo "Timed out waiting for the guest"
        cat serial.log
        exit 1
    fi
    sleep 2
done

echo "Guest ready after $((SECONDS - start)) s"
