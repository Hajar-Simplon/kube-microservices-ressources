# Highly Available Microservices on Kubernetes

This project deploys an application composed of an API Gateway and two
microservices (`books` and `movies`) on a Kind cluster with nine worker nodes.
The workers simulate three availability zones in the `francecentral` region.

## Architecture

```text
Host: http://localhost:8080/data
                 |
       NodePort 30080
                 |
          API Gateway x3
            /          \
      Books x3        Movies x3
```

Each application has three replicas. Strict pod anti-affinity on
`topology.kubernetes.io/zone` requires one replica in each zone. Preferred
anti-affinity on `kubernetes.io/hostname` also encourages the scheduler to use
less occupied nodes.

| Zone | Workers |
| --- | --- |
| `francecentral-1` | `worker`, `worker2`, `worker3` |
| `francecentral-2` | `worker4`, `worker5`, `worker6` |
| `francecentral-3` | `worker7`, `worker8`, `worker9` |

## Prerequisites

- Docker Engine or Docker Desktop
- Kind
- kubectl
- Helm
- GNU Make and Bash
- Go for local tests

Verify the tools:

```bash
docker version
kind version
kubectl version --client
helm version
go version
```

## Deployment

The complete command creates the cluster, labels the nodes before scheduling,
builds the image, loads it into Kind, and installs the Helm chart:

```bash
make deploy
```

The steps can also be executed separately:

```bash
make cluster
make labels
make build TAG=1.0.0
make load TAG=1.0.0
make install TAG=1.0.0
```

Verify the deployment:

```bash
make nodes
make pods
make services
curl http://localhost:8080/data
```

The response should contain the books and movies data. `make pods` should show
one replica of each application in each of the three zones.

## High Availability

### Health probes

Every container exposes `/health` and defines:

- a `startupProbe` to protect the startup phase;
- a `readinessProbe` to remove an unready pod from Service endpoints;
- a `livenessProbe` to let Kubernetes restart an unresponsive process.

### Rolling Update

All three Deployments use:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1
    maxSurge: 1
```

`maxUnavailable: 1` is required with strict zone anti-affinity. Because all
three zones are already occupied, Kubernetes must first free a zone before it
can place the new version there. The other two replicas continue serving
traffic during this step.

For the demonstration, open three terminals.

Terminal 1:

```bash
make watch-pods
```

Terminal 2:

```bash
make measure
```

Terminal 3, after building and loading a new image:

```bash
make build TAG=2.0.0
make load TAG=2.0.0
make upgrade TAG=2.0.0
```

`helm upgrade` changes the image tag, and `kubectl rollout status` waits for all
three rollouts to succeed. Siege should continue receiving responses while the
pods are replaced progressively.

### PodDisruptionBudget

Each application has a PDB with `minAvailable: 2`. A voluntary drain can
therefore evict no more than one replica of an application at a time. A PDB
protects against voluntary evictions, but it cannot prevent an abrupt node
failure.

## Load and Chaos Tests

The load-test script uses a locally installed Siege binary when available. Its
fallback starts a current Ubuntu container and installs Siege inside that
temporary container. The defaults are 20 concurrent clients for one minute.

Optional parameters:

```bash
CONCURRENT=50 DURATION=2M make measure
```

From PowerShell:

```powershell
$env:CONCURRENT = "50"
$env:DURATION = "2M"
make measure
```

### Scenario 1 — Normal operation

```bash
make measure
```

Expected result: 100% availability, except for possible laptop resource
variations.

### Scenario 2 — Loss of one worker

Start `make measure`, then run this command in another terminal:

```bash
make node-down
```

The default node is `microservices-chaos-worker`. Select a different node with:

```bash
NODE=microservices-chaos-worker5 make node-down
```

From PowerShell:

```powershell
$env:NODE = "microservices-chaos-worker5"
make node-down
```

Expected result: evicted pods are recreated on another worker in the same zone,
and the error rate remains low.

### Scenario 3 — Loss of an entire zone

Start `make measure`, then run:

```bash
make zone-down
```

The default zone is `francecentral-1`. Select a different zone with:

```bash
ZONE=francecentral-2 make zone-down
```

From PowerShell:

```powershell
$env:ZONE = "francecentral-2"
make zone-down
```

Expected result: two replicas of every application remain available. The third
replica remains `Pending` because strict anti-affinity prevents two replicas
from running in the same zone. This is the chosen tradeoff between reduced
capacity and strict topology compliance.

Restore all workers after each experiment:

```bash
make recover
```

## Theoretical Failure Analysis

- **Application running on one node:** losing that node causes an outage until
  Kubernetes detects the failure and reschedules the pod.
- **One node lost in every zone:** the application remains available when its
  pods were not running on those nodes. Otherwise, Kubernetes recreates each
  affected replica on one of the two remaining workers in its zone.
- **One entire zone lost:** one replica of every application disappears. The
  other two zones continue serving traffic, but capacity drops by roughly one
  third. With strict spreading, Kubernetes does not violate the policy to
  create a third replica in a surviving zone.

The orchestrator provides health-state detection, removal of unready endpoints,
rescheduling, convergence toward the declared state, and progressive version
replacement. It cannot eliminate every transient error instantly. Detection
delays, existing connections, and laptop resource constraints can explain
occasional failures reported by Siege.

## Useful Commands

```bash
helm lint helm/microservices
helm template microservices helm/microservices --namespace microservices
kubectl get pods -n microservices -o wide
kubectl get pdb -n microservices
kubectl get endpointslices -n microservices
kubectl rollout history deployment/microservices-api -n microservices
```

Cleanup:

```bash
make clean
make delete-cluster
```
