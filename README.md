# High Availability Microservices with Kubernetes & Helm

## Overview

This project demonstrates the deployment of a highly available microservices application on Kubernetes using Helm.

The infrastructure is deployed on a local Kind (Kubernetes in Docker) cluster composed of one control plane and nine worker nodes distributed across three simulated Availability Zones.

The project focuses on:

- Kubernetes High Availability
- Helm packaging
- Rolling updates
- Health probes
- Pod Anti-Affinity
- Multi-zone scheduling
- Chaos Engineering
- Load testing

---

# Architecture

```
                   +--------------------+
                   |    API Gateway     |
                   +---------+----------+
                             |
               +-------------+-------------+
               |                           |
        +------+-------+           +-------+------+
        | Books Service|           | Movies Service|
        +--------------+           +--------------+

```

The API Gateway aggregates responses from the Books and Movies services.

---

# Technologies

- Go
- Gin
- Docker
- Kubernetes
- Helm 3
- Kind
- Bash
- GNU Make

---

# Project Structure

```
.
├── cmd/
│   └── api/
│       └── main.go
│
├── helm/
│   └── microservices/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── namespace.yaml
│           ├── configmap.yaml
│           ├── api-deployment.yaml
│           └── api-service.yaml
│
├── k8s/
│
├── scripts/
│   └── labels.sh
│
├── Dockerfile
├── Makefile
├── kind-config.yaml
└── README.md
```

---

# Cluster Architecture

The project uses a Kind cluster composed of:

- 1 Control Plane
- 9 Worker Nodes

Workers are distributed into three simulated Availability Zones.

| Zone | Nodes |
|------|-------|
| zone-a | worker1 worker2 worker3 |
| zone-b | worker4 worker5 worker6 |
| zone-c | worker7 worker8 worker9 |

---

# High Availability Features

## Rolling Update

The API Deployment uses a RollingUpdate strategy.

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1
    maxSurge: 1
```

This ensures application availability during updates.

---

## Pod Anti-Affinity

The API replicas cannot be scheduled on the same worker node.

```yaml
requiredDuringSchedulingIgnoredDuringExecution
```

This protects the application against node failures.

---

## Health Probes

The API exposes:

```
GET /health
```

Three probes are configured:

- Startup Probe
- Readiness Probe
- Liveness Probe

These probes ensure unhealthy containers are automatically detected and restarted.

---

# Helm

The project is deployed using Helm.

Current templates:

- Namespace
- ConfigMap
- API Deployment
- API Service

Deployment configuration is centralized inside:

```
values.yaml
```

---

# Build

Build the API image:

```bash
make build
```

---

# Load Image into Kind

```bash
make load
```

---

# Create Cluster

```bash
make cluster
```

---

# Label Availability Zones

```bash
make labels
```

---

# Install the Helm Chart

```bash
make install
```

---

# Upgrade After Changes

```bash
make deploy
```

or

```bash
make upgrade
```

---

# Useful Commands

Display nodes and zones:

```bash
make nodes
```

Display pods:

```bash
make pods
```

Display all resources:

```bash
make all
```

Display logs:

```bash
make logs
```

Restart deployment:

```bash
make restart
```

---

# Deployment Verification

Verify node labels:

```bash
kubectl get nodes -L topology.kubernetes.io/zone
```

Verify pod placement:

```bash
kubectl get pods -n microservices -o wide
```

Expected result:

- API replicas running on different worker nodes.

---

# Chaos Engineering

The project is designed to support Chaos Engineering scenarios.

Examples include:

- Worker node failure
- Availability Zone failure
- Pod deletion
- Rolling update validation

---

# Load Testing

Load testing will be performed using Siege.

Example:

```bash
siege -c 20 -t 1M http://localhost:PORT/data
```

Metrics observed:

- Availability
- Throughput
- Response time

---


# Future Work

- Deploy Books service through Helm
- Deploy Movies service through Helm
- Full application deployment
- Chaos Engineering demonstrations
- Load testing report
- Production Ingress/Gateway