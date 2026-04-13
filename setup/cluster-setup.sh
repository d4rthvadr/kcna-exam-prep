#!/bin/bash

# CKNA Exam Prep - Cluster Setup Script
# This script initializes a local Kubernetes cluster with required tools

set -e

echo "================================"
echo "KCNA Exam Prep - Cluster Setup"
echo "================================"
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    echo "   macOS: brew install kubectl"
    echo "   Linux: curl -LO https://dl.k8s.io/release/stable.txt && curl -LO https://dl.k8s.io/release/v\$(cat stable.txt)/bin/linux/amd64/kubectl"
    exit 1
fi

echo "✅ kubectl found: $(kubectl version --client -o json | grep -o '"gitVersion":"[^"]*"')"

# Check if a cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo ""
    echo "❌ No Kubernetes cluster found."
    echo ""
    echo "Please start a local cluster using one of:"
    echo ""
    echo "  1. Docker Desktop:"
    echo "     - Open Docker Desktop Settings → Kubernetes → Enable Kubernetes"
    echo ""
    echo "  2. Minikube:"
    echo "     brew install minikube"
    echo "     minikube start --driver=docker --cpus=4 --memory=8192"
    echo ""
    echo "  3. kind (Kubernetes in Docker):"
    echo "     brew install kind"
    echo "     kind create cluster --name kcna-prep"
    echo ""
    exit 1
fi

echo "✅ Kubernetes cluster is accessible"
echo ""

# Display cluster info
echo "Cluster Information:"
kubectl cluster-info
echo ""

# Check cluster nodes
echo "Cluster Nodes:"
kubectl get nodes
echo ""

# Check if metrics-server is installed
echo "Checking for metrics-server (required for HPA)..."
if kubectl get deployment metrics-server -n kube-system &> /dev/null; then
    echo "✅ metrics-server is already installed"
else
    echo "⚠️  metrics-server not found. Installing..."
    
    # Try to install metrics-server
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    
    # Wait for metrics-server to be ready
    echo "Waiting for metrics-server to be ready..."
    kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=300s || true
    
    echo "✅ metrics-server installed"
fi
echo ""

# Create required namespaces
echo "Setting up namespaces..."
kubectl create namespace default --dry-run=client -o yaml | kubectl apply -f -
echo "✅ Namespaces ready"
echo ""

# Display summary
echo "================================"
echo "Setup Complete!"
echo "================================"
echo ""
echo "Cluster Ready for KCNA Exam Prep"
echo "- Node count: $(kubectl get nodes --no-headers | wc -l)"
echo "- Namespaces: $(kubectl get namespaces --no-headers | wc -l)"
echo "- metrics-server: $(kubectl get deployment metrics-server -n kube-system --no-headers 2>/dev/null | awk '{print $2}' || echo 'not installed')"
echo ""
echo "Next steps:"
echo "1. Run: chmod +x setup/verify-setup.sh && ./setup/verify-setup.sh"
echo "2. Read: README.md for learning path"
echo "3. Start: cd 01-beginner && cat README.md"
echo ""
