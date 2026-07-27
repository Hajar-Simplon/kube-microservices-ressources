#!/usr/bin/env bash
set -euo pipefail

URL="${URL:-http://host.docker.internal:8080/data}"
CONCURRENT="${CONCURRENT:-20}"
DURATION="${DURATION:-1M}"

echo "Load test: ${URL} (${CONCURRENT} clients for ${DURATION})"

if command -v siege >/dev/null 2>&1; then
  siege -c "${CONCURRENT}" -t "${DURATION}" "${URL/host.docker.internal/localhost}"
elif command -v docker >/dev/null 2>&1; then
  docker run --rm \
    --add-host=host.docker.internal:host-gateway \
    --env "TARGET_URL=${URL}" \
    --env "CONCURRENT=${CONCURRENT}" \
    --env "DURATION=${DURATION}" \
    ubuntu:24.04 \
    bash -c '
      apt-get update -qq &&
      DEBIAN_FRONTEND=noninteractive apt-get install -y -qq siege >/dev/null &&
      siege -c "${CONCURRENT}" -t "${DURATION}" "${TARGET_URL}"
    '
else
  echo "Siege or Docker is required." >&2
  exit 1
fi
