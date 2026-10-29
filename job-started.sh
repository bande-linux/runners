#!/bin/bash
# The five runners' /work and /cache volumes share one VM disk, so a runner drops its own build
# outputs before a job when that disk runs low. Caches in /cache are bounded by their own limits.
min_free_gib=30
free_gib=$(( $(df -Pk /work | awk 'NR == 2 { print $4 }') / 1024 / 1024 ))
[ "$free_gib" -ge "$min_free_gib" ] && exit 0
echo "Runner disk has ${free_gib} GiB free; removing this runner's untracked build outputs"
for git_dir in /work/*/*/.git; do
    git -C "${git_dir%/.git}" clean -ffdxq
done
exit 0
