#!/bin/bash
# Keeps the shared build cache under BUILD_CACHE_GIB by deleting the least recently read
# entries, and drops uploads that were never finished.
set -euo pipefail

root=/var/cache/build
limit=$(( ${BUILD_CACHE_GIB:-20} * 1024 * 1024 * 1024 ))
target=$(( limit * 9 / 10 ))

while true; do
    mkdir -p "$root/.incoming"
    find "$root/.incoming" -type f -mmin +60 -delete
    used=$(du -sb --exclude=.incoming "$root" | cut -f1)
    if [ "$used" -gt "$limit" ]; then
        while read -r _ size path; do
            [ "$used" -le "$target" ] && break
            rm -f -- "$path"
            used=$(( used - size ))
        done < <(find "$root" -path "$root/.incoming" -prune -o -type f -printf '%A@ %s %p\n' | sort -n)
        echo "build cache trimmed to $(( used / 1024 / 1024 )) MiB"
    fi
    sleep "${BUILD_CACHE_TRIM_INTERVAL:-600}"
done
