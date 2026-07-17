#!/usr/bin/env bash
# Start Colima — a lightweight Lima-backed VM that runs the Docker daemon locally,
# a drop-in Docker Desktop alternative. Idempotent: a no-op once the VM is running.
#
# `colima status` exits 0 only when the default profile's VM is up and the Docker
# socket is live, so this mirrors the step's check exactly. On first run it boots
# the VM (a minute or two); afterwards it exits fast.
set -euo pipefail

if colima status >/dev/null 2>&1; then
  echo "Colima already running."
  exit 0
fi

# `colima start` is idempotent itself, but gating on status keeps plan/apply honest
# and avoids the startup churn when it's already up. Tune CPU/memory/disk to taste.
colima start --cpus 4 --memory 8 --disk 60
echo "Colima started — 'docker ps' now talks to the Colima daemon."
