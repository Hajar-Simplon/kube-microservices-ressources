#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-kube-microservices-ressources}"
NAMESPACE="${NAMESPACE:-microservices}"
NODE="${NODE:-${CLUSTER_NAME}-worker}"

echo "Draining node ${NODE}..."
kubectl drain "${NODE}" \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --timeout=120s

kubectl get pods -n "${NAMESPACE}" -o wide
echo "Restore it later with: kubectl uncordon ${NODE}"
