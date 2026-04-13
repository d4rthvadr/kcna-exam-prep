#!/bin/bash

# CKNA Exam Prep - Cluster Verification Script
# This script verifies that the cluster is properly configured for exercises

set -e

echo "================================"
echo "KCNA Exam Prep - Cluster Verification"
echo "================================"
echo ""

# Check kubectl
echo "Checking kubectl..."
if ! command -v kubectl &> /dev/null; then
    echo "kubectl not found"
    exit 1
fi
echo "✅ kubectl installed"

# Check cluster connectivity
echo "Checking cluster connectivity..."
if ! kubectl cluster-info &> /dev/null; then
    echo "Cannot connect to Kubernetes cluster"
    echo "   Make sure your cluster is running (Docker Desktop, minikube, kind, etc.)"
    exit 1
fi
echo "✅ Connected to cluster"

# Check nodes
echo "Checking cluster nodes..."
node_count=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
if [ "$node_count" -eq 0 ]; then
    echo "No nodes found in cluster"
    exit 1
fi
echo "Found $node_count node(s)"

# Check default namespace
echo "Checking default namespace..."
if ! kubectl get namespace default &> /dev/null; then
    echo "default namespace not found"
    exit 1
fi
echo "default namespace available"

# Check metrics-server (for HPA exercises)
echo "Checking metrics-server..."
if kubectl get deployment metrics-server -n kube-system &> /dev/null; then
    metrics_status=$(kubectl get deployment metrics-server -n kube-system -o jsonpath='{.status.readyReplicas}')
    if [ "$metrics_status" -gt 0 ]; then
        echo "metrics-server is ready"
    else
        echo "metrics-server found but not yet fully ready (still initializing)"
    fi
else
    echo "metrics-server not installed (needed for HPA exercises)"
    echo "   Optional: Run ./setup/cluster-setup.sh to install"
fi

# Check API server responsiveness
echo "Checking API server..."
if kubectl version --short &> /dev/null; then
    echo "API server is responsive"
else
    echo "API server not responding"
    exit 1
fi

# Display resource info
echo ""
echo "================================"
echo "Cluster Status"
echo "================================"
echo ""
echo "Nodes:"
kubectl get nodes
echo ""

echo "Namespaces:"
kubectl get namespaces
echo ""

echo "Pod Status (all namespaces):"
pod_count=$(kubectl get pods --all-namespaces --no-headers | wc -l)
running=$(kubectl get pods --all-namespaces --field-selector=status.phase=Running --no-headers | wc -l)
echo "   Total: $pod_count, Running: $running"
echo ""

echo "================================"
echo "Verification Complete!"
echo "================================"
echo ""
echo "Your cluster is ready for KCNA exam prep exercises"
echo ""
echo "Quick test:"
echo "  kubectl run test-pod --image=nginx:latest"
echo "  kubectl delete pod test-pod"
echo ""
echo "Start learning:"
echo "  cat README.md"
echo "  cd 01-beginner && cat README.md"
echo ""
