#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-microservices}"
HELM_RELEASE="${HELM_RELEASE:-microservices}"
TEST_POD="${TEST_POD:-limitrange-test}"
DEPLOYMENT="${DEPLOYMENT:-${HELM_RELEASE}-books}"

original_replicas="$(
  kubectl get deployment "${DEPLOYMENT}" \
    -n "${NAMESPACE}" \
    -o jsonpath='{.spec.replicas}'
)"

cleanup() {
  kubectl delete pod "${TEST_POD}" \
    -n "${NAMESPACE}" \
    --ignore-not-found \
    --wait=false >/dev/null
  kubectl scale deployment "${DEPLOYMENT}" \
    -n "${NAMESPACE}" \
    --replicas="${original_replicas}" >/dev/null
}
trap cleanup EXIT

echo "Testing LimitRange default injection..."
kubectl run "${TEST_POD}" \
  -n "${NAMESPACE}" \
  --image=busybox:1.36 \
  --restart=Never \
  --command -- sleep 300

kubectl wait pod "${TEST_POD}" \
  -n "${NAMESPACE}" \
  --for=jsonpath='{.status.phase}'=Running \
  --timeout=90s

echo "Injected resources:"
kubectl get pod "${TEST_POD}" \
  -n "${NAMESPACE}" \
  -o jsonpath='{.spec.containers[0].resources}'
echo

kubectl delete pod "${TEST_POD}" \
  -n "${NAMESPACE}" \
  --wait=true

echo
echo "Testing ResourceQuota by requesting two additional replicas..."
kubectl scale deployment "${DEPLOYMENT}" \
  -n "${NAMESPACE}" \
  --replicas="$((original_replicas + 2))"

sleep 10

kubectl get deployment "${DEPLOYMENT}" -n "${NAMESPACE}"
kubectl get pods -n "${NAMESPACE}"

replicaset="$(
  kubectl get replicasets \
    -n "${NAMESPACE}" \
    -l app=books \
    --sort-by=.metadata.creationTimestamp \
    -o name |
    tail -n 1
)"

echo
echo "ReplicaSet events (look for FailedCreate and exceeded quota):"
kubectl describe "${replicaset}" -n "${NAMESPACE}"

echo
echo "Quota usage:"
kubectl describe quota "${HELM_RELEASE}-compute-quota" \
  -n "${NAMESPACE}"

echo
echo "The original replica count will be restored automatically."
