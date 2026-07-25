#!/usr/bin/env bash
set -euo pipefail

mapfile -t NODES < <(
  kubectl get nodes \
    -l 'node-role.kubernetes.io/control-plane!=' \
    -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
)

for node in "${NODES[@]}"; do
  kubectl uncordon "${node}"
done

kubectl get nodes -L topology.kubernetes.io/zone
