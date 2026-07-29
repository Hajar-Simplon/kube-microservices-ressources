#!/usr/bin/env bash
set -euo pipefail

METRICS_SERVER_VERSION="${METRICS_SERVER_VERSION:-v0.9.0}"

if ! kubectl get --raw=/readyz >/dev/null 2>&1; then
  echo "kubectl is not connected to a ready Kubernetes cluster." >&2
  echo "Create the Kind cluster or select the correct kubectl context first." >&2
  exit 1
fi

echo "Installing metrics-server ${METRICS_SERVER_VERSION}..."
kubectl apply -f \
  "https://github.com/kubernetes-sigs/metrics-server/releases/download/${METRICS_SERVER_VERSION}/components.yaml"

if ! kubectl get deployment metrics-server -n kube-system \
  -o jsonpath='{.spec.template.spec.containers[0].args}' |
  grep -q -- '--kubelet-insecure-tls'; then
  kubectl patch deployment metrics-server \
    -n kube-system \
    --type=json \
    -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
fi

kubectl rollout status deployment/metrics-server \
  -n kube-system \
  --timeout=120s

echo "metrics-server is ready. Metrics can take up to one minute to appear."
kubectl get pods -n kube-system -l k8s-app=metrics-server
