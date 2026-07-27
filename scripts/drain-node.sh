#!/usr/bin/env bash
set -euo pipefail

NODE="${NODE:-microservices-chaos-worker}"

echo "Draining node ${NODE}..."
kubectl drain "${NODE}" \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --timeout=120s

kubectl get pods -n microservices -o wide
echo "Restore it later with: kubectl uncordon ${NODE}"
