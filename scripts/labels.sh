#!/usr/bin/env bash
set -euo pipefail

echo "Waiting for the Kubernetes API server..."
for attempt in {1..60}; do
  if kubectl get --raw=/readyz >/dev/null 2>&1; then
    break
  fi
  if [ "${attempt}" -eq 60 ]; then
    echo "The Kubernetes API server did not become ready." >&2
    exit 1
  fi
  sleep 2
done

kubectl wait --for=condition=Ready nodes --all --timeout=300s

label_node() {
  local node="$1"
  local zone="$2"

  for attempt in {1..10}; do
    if kubectl label node "${node}" \
      topology.kubernetes.io/region=francecentral \
      "topology.kubernetes.io/zone=${zone}" \
      --overwrite; then
      return 0
    fi
    if [ "${attempt}" -eq 10 ]; then
      echo "Failed to label ${node} after ${attempt} attempts." >&2
      return 1
    fi
    sleep 3
  done
}

echo "Labeling worker nodes..."

# Zone 1
label_node microservices-chaos-worker francecentral-1
label_node microservices-chaos-worker2 francecentral-1
label_node microservices-chaos-worker3 francecentral-1

# Zone 2
label_node microservices-chaos-worker4 francecentral-2
label_node microservices-chaos-worker5 francecentral-2
label_node microservices-chaos-worker6 francecentral-2

# Zone 3
label_node microservices-chaos-worker7 francecentral-3
label_node microservices-chaos-worker8 francecentral-3
label_node microservices-chaos-worker9 francecentral-3

echo "All worker nodes have been labeled."
