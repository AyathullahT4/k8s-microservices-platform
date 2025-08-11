#!/usr/bin/env bash
set -e

CLUSTER_NAME="kdev"

echo "Deleting Kind cluster: $CLUSTER_NAME"
kind delete cluster --name "$CLUSTER_NAME"

echo "Kind cluster '$CLUSTER_NAME' deleted."
