#!/usr/bin/env bash
set -e

CLUSTER_NAME="kdev"

echo "Creating Kind cluster: $CLUSTER_NAME"
kind create cluster --name "$CLUSTER_NAME" --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 80
        hostPort: 8080
      - containerPort: 443
        hostPort: 8443
EOF

echo "Kind cluster '$CLUSTER_NAME' created."
