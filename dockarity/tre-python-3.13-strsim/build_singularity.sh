#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="tre-python-3.13-strsim"
TAG="${1:-latest}"
SIF="singularity.sif"

echo "==> Building Docker image ${IMAGE_NAME}:${TAG} ..."
docker build -t "${IMAGE_NAME}:${TAG}" .

echo "==> Converting to Singularity SIF: ${SIF} ..."
singularity build --force "${SIF}" "docker-daemon://${IMAGE_NAME}:${TAG}"

echo "==> Verifying ..."
singularity exec "${SIF}" python3 -c "
import sys, polars_strsim, polars_distance, rapidfuzz, tretools
print(f'Python: {sys.version.split()[0]}')
print('polars_strsim OK')
print('tretools OK')
"

echo "==> Done: ${SIF}"
