# Kubernetes Resource Management

## Resource Sizing

Each `api`, `books`, and `movies` container requests `100m` of CPU and `64Mi`
of memory. Each container is limited to `200m` of CPU and `128Mi` of memory.

With three replicas per service (nine Pods), the application reserves `900m`
of CPU and `576Mi` of memory. It can consume up to `1800m` of CPU and `1152Mi`
of memory.

- A request is used by the scheduler and represents the reserved capacity.
- Reaching the CPU limit causes throttling.
- The memory limit is strict: exceeding it can cause an `OOMKilled` event,
  followed by a container restart.

These values are a starting point. In production, they should be adjusted
using `kubectl top`, telemetry percentiles, and representative load tests.

## Namespace Policies

The `LimitRange`:

- injects a `50m`/`64Mi` request and a `250m`/`256Mi` limit into containers
  that do not declare their own resources;
- rejects containers configured below `10m`/`16Mi` or above `500m`/`512Mi`.

The `ResourceQuota` allows the following totals:

| Resource | Quota | Normal application usage |
| --- | ---: | ---: |
| requests.cpu | 1200m | 900m |
| requests.memory | 768Mi | 576Mi |
| limits.cpu | 2400m | 1800m |
| limits.memory | 1536Mi | 1152Mi |
| pods | 10 | 9 |

This margin allows one additional Pod during an update or test without letting
the namespace monopolize the cluster.

## Verification

Install the application and verify its resources:

```bash
make deploy
make top
make limits
make quota
make verify-resources
kubectl get pods -n microservices
```

Check the resource values applied to the Deployments:

```bash
kubectl get deployments -n microservices \
  -o custom-columns='NAME:.metadata.name,CPU_REQ:.spec.template.spec.containers[0].resources.requests.cpu,MEM_REQ:.spec.template.spec.containers[0].resources.requests.memory,CPU_LIMIT:.spec.template.spec.containers[0].resources.limits.cpu,MEM_LIMIT:.spec.template.spec.containers[0].resources.limits.memory'
```

## ResourceQuota Demonstration

With nine active Pods and a limit of ten Pods, request two additional
replicas:

```bash
kubectl scale deployment/microservices-books -n microservices --replicas=5
kubectl get deployment microservices-books -n microservices
kubectl get events -n microservices --sort-by=.lastTimestamp
kubectl describe replicaset -n microservices \
  "$(kubectl get rs -n microservices -l app=books -o jsonpath='{.items[0].metadata.name}')"
make quota
```

The first Pod can be created. The admission controller rejects the next Pod
with a `FailedCreate` event containing `exceeded quota`. The Deployment remains
one replica short.

Note: exceeding a `ResourceQuota` does not normally create a Pod object in the
`Pending` phase. The API rejects the Pod before it is created. The correct
evidence is therefore an incomplete Deployment and a `FailedCreate` event. A
real `Pending` Pod is more commonly produced when the scheduler cannot find
capacity that satisfies its requests.

Capture the following output for the deliverables:

```bash
kubectl get deployment microservices-books -n microservices
kubectl get events -n microservices --sort-by=.lastTimestamp
kubectl describe quota microservices-compute-quota -n microservices
```

The LimitRange and ResourceQuota checks can also be run as one reproducible
test. It creates a temporary Pod, displays the injected default resources,
triggers the quota failure, prints the evidence, and restores the original
replica count:

```bash
make test-resource-policies
```

Restore the normal replica count afterward:

```bash
kubectl scale deployment/microservices-books -n microservices --replicas=3
kubectl rollout status deployment/microservices-books -n microservices
```

## CPU Throttling Test

Create a temporary values file:

```yaml
books:
  resources:
    requests:
      cpu: "1m"
      memory: "64Mi"
    limits:
      cpu: "1m"
      memory: "128Mi"
```

Apply the override, generate load, and compare latency and resource usage:

```bash
helm upgrade microservices helm/microservices -n microservices \
  -f throttle-values.yaml
make measure
make top
```

A `1m` limit is intentionally extreme and should only be used for the
demonstration. The current `LimitRange` rejects it because its minimum is
`10m`. For this educational test, temporarily lower the minimum to `1m`, then
restore the repository values.
