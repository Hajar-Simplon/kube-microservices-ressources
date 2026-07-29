# ==========================================
# High Availability Microservices - Makefile
# ==========================================

# Variables
CLUSTER_NAME := kube-microservices-ressources
HELM_RELEASE := microservices
HELM_CHART := helm/microservices
NAMESPACE := microservices
TAG ?= 1.0.0
IMAGE := kube-microservices:$(TAG)
METRICS_SERVER_VERSION ?= v0.9.0

# ==========================================
# Kind Cluster
# ==========================================

cluster:
	kind create cluster --name $(CLUSTER_NAME) --config kind-config.yaml

delete-cluster:
	kind delete cluster --name $(CLUSTER_NAME)

nodes:
	kubectl get nodes -L topology.kubernetes.io/region,topology.kubernetes.io/zone

metrics-server:
	METRICS_SERVER_VERSION=$(METRICS_SERVER_VERSION) bash scripts/install-metrics-server.sh

# ==========================================
# Labels
# ==========================================

labels:
	CLUSTER_NAME=$(CLUSTER_NAME) bash scripts/labels.sh

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
	helm upgrade --install $(HELM_RELEASE) $(HELM_CHART) --namespace $(NAMESPACE) --create-namespace --set global.image.tag=$(TAG)

upgrade:
	helm upgrade $(HELM_RELEASE) $(HELM_CHART) --namespace $(NAMESPACE) --set global.image.tag=$(TAG)
	kubectl rollout status deployment/$(HELM_RELEASE)-api -n $(NAMESPACE)
	kubectl rollout status deployment/$(HELM_RELEASE)-books -n $(NAMESPACE)
	kubectl rollout status deployment/$(HELM_RELEASE)-movies -n $(NAMESPACE)

uninstall:
	helm uninstall $(HELM_RELEASE) --namespace $(NAMESPACE)

# ==========================================
# Kubernetes
# ==========================================

pods:
	kubectl get pods -n $(NAMESPACE) -o wide

services:
	kubectl get svc -n $(NAMESPACE)

deployments:
	kubectl get deployments -n $(NAMESPACE)

top:
	kubectl top pods -n $(NAMESPACE)

quota:
	kubectl describe quota $(HELM_RELEASE)-compute-quota -n $(NAMESPACE)

limits:
	kubectl describe limitrange $(HELM_RELEASE)-container-limits -n $(NAMESPACE)

verify-resources:
	NAMESPACE=$(NAMESPACE) HELM_RELEASE=$(HELM_RELEASE) bash scripts/verify-resources.sh

test-resource-policies:
	NAMESPACE=$(NAMESPACE) HELM_RELEASE=$(HELM_RELEASE) bash scripts/test-resource-policies.sh

all:
	kubectl get all -n $(NAMESPACE)

logs:
	kubectl logs -n $(NAMESPACE) deployment/microservices-api

restart:
	kubectl rollout restart deployment microservices-api -n $(NAMESPACE)

describe:
	kubectl describe deployment microservices-api -n $(NAMESPACE)

# ==========================================
# Cleanup
# ==========================================

clean:
	helm uninstall $(HELM_RELEASE) --namespace $(NAMESPACE) || true

reset: clean delete-cluster

# ==========================================
# Complete Local Deployment
# ==========================================

deploy: cluster labels metrics-server build load install

# ==========================================
# Chaos Experiments
# ==========================================

watch-pods:
	kubectl get pods -n $(NAMESPACE) -o wide --watch

measure:
	bash scripts/load-test.sh

node-down:
	CLUSTER_NAME=$(CLUSTER_NAME) NAMESPACE=$(NAMESPACE) bash scripts/drain-node.sh

zone-down:
	NAMESPACE=$(NAMESPACE) bash scripts/drain-zone.sh

recover:
	bash scripts/recover.sh
