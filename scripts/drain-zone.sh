#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-microservices}"
ZONE="${ZONE:-francecentral-1}"

mapfile -t NODES < <(
  kubectl get nodes \
    -l "topology.kubernetes.io/zone=${ZONE}" \
    -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
)

if [ "${#NODES[@]}" -eq 0 ]; then
  echo "No nodes found in zone ${ZONE}." >&2
  exit 1
fi

echo "Draining zone ${ZONE}: ${NODES[*]}"
for node in "${NODES[@]}"; do
  kubectl drain "${node}" \
    --ignore-daemonsets \
    --delete-emptydir-data \
    --timeout=120s
done

kubectl get pods -n "${NAMESPACE}" -o wide
echo "Run 'make recover' to uncordon all workers."
