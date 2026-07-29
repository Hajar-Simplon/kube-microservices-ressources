#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-microservices}"
HELM_RELEASE="${HELM_RELEASE:-microservices}"

echo "Application Pods:"
kubectl get pods -n "${NAMESPACE}" -o wide

echo
echo "Deployment requests and limits:"
kubectl get deployments -n "${NAMESPACE}" \
  -o custom-columns='NAME:.metadata.name,CPU_REQUEST:.spec.template.spec.containers[0].resources.requests.cpu,MEMORY_REQUEST:.spec.template.spec.containers[0].resources.requests.memory,CPU_LIMIT:.spec.template.spec.containers[0].resources.limits.cpu,MEMORY_LIMIT:.spec.template.spec.containers[0].resources.limits.memory'

echo
echo "LimitRange:"
kubectl describe limitrange "${HELM_RELEASE}-container-limits" \
  -n "${NAMESPACE}"

echo
echo "ResourceQuota:"
kubectl describe quota "${HELM_RELEASE}-compute-quota" \
  -n "${NAMESPACE}"

echo
echo "Current Pod usage:"
if ! kubectl top pods -n "${NAMESPACE}"; then
  echo "Metrics are not available yet. Wait one minute and run this script again." >&2
fi
