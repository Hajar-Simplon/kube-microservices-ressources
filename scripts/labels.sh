#!/bin/bash

echo "Labeling worker nodes..."

# Zone A
kubectl label node microservices-chaos-worker topology.kubernetes.io/zone=zone-a --overwrite
kubectl label node microservices-chaos-worker2 topology.kubernetes.io/zone=zone-a --overwrite
kubectl label node microservices-chaos-worker3 topology.kubernetes.io/zone=zone-a --overwrite

# Zone B
kubectl label node microservices-chaos-worker4 topology.kubernetes.io/zone=zone-b --overwrite
kubectl label node microservices-chaos-worker5 topology.kubernetes.io/zone=zone-b --overwrite
kubectl label node microservices-chaos-worker6 topology.kubernetes.io/zone=zone-b --overwrite

# Zone C
kubectl label node microservices-chaos-worker7 topology.kubernetes.io/zone=zone-c --overwrite
kubectl label node microservices-chaos-worker8 topology.kubernetes.io/zone=zone-c --overwrite
kubectl label node microservices-chaos-worker9 topology.kubernetes.io/zone=zone-c --overwrite

echo "Done!"