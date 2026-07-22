# ==========================================
# High Availability Microservices - Makefile
# ==========================================

# Variables
CLUSTER_NAME := microservices-chaos
HELM_RELEASE := microservices
HELM_CHART := helm/microservices
NAMESPACE := microservices
IMAGE := kube-microservices:latest

# ==========================================
# Kind Cluster
# ==========================================

cluster:
	kind create cluster --name $(CLUSTER_NAME) --config kind-config.yaml

delete-cluster:
	kind delete cluster --name $(CLUSTER_NAME)

nodes:
	kubectl get nodes -L topology.kubernetes.io/zone

# ==========================================
# Labels
# ==========================================

labels:
	chmod +x scripts/labels.sh
	./scripts/labels.sh

# ==========================================
# Docker
# ==========================================

build:
	docker build -t $(IMAGE) .

load:
	kind load docker-image $(IMAGE) --name $(CLUSTER_NAME)

rebuild: build load

# ==========================================
# Helm
# ==========================================

lint:
	helm lint $(HELM_CHART)

template:
	helm template $(HELM_RELEASE) $(HELM_CHART)

install:
	helm install $(HELM_RELEASE) $(HELM_CHART) -n microservices --create-namespace

upgrade:
	helm upgrade $(HELM_RELEASE) $(HELM_CHART)

uninstall:
	helm uninstall $(HELM_RELEASE)

# ==========================================
# Kubernetes
# ==========================================

pods:
	kubectl get pods -n $(NAMESPACE) -o wide

services:
	kubectl get svc -n $(NAMESPACE)

deployments:
	kubectl get deployments -n $(NAMESPACE)

all:
	kubectl get all -n $(NAMESPACE)

logs:
	kubectl logs -n $(NAMESPACE) deployment/microservices-api

restart:
	kubectl rollout restart deployment microservices-api -n $(NAMESPACE)

describe:
	kubectl describe deployment microservices-api -n $(NAMESPACE)

port-forward-api:
	kubectl port-forward -n $(NAMESPACE) svc/api-service 8080:80

# ==========================================
# Cleanup
# ==========================================

clean:
	helm uninstall $(HELM_RELEASE) || true

reset: clean delete-cluster

# ==========================================
# Complete Local Deployment
# ==========================================

deploy: cluster build load install labels

deploy-local: deploy port-forward-api

# ==========================================
# Chaos Experiments
# ==========================================

watch-pods:
	watch -n 1 kubectl get pods -n $(NAMESPACE) -o wide

measure:

node-down:


zone-down:
