#!/bin/bash
# kubectl apply -f index_green_html.yml
# kubectl apply -f green.yml

set -e

# Define service and namespace
SERVICE="green-svc"
NAMESPACE="udacity"

# Deploy the green deployment
kubectl apply -f green.yml

# Function to wait for a deployment to be ready
wait_for_deployment() {
  local namespace=$1
  local deployment=$2
  echo "Waiting for deployment $deployment in namespace $namespace to roll out..."
  kubectl rollout status deployment/$deployment --namespace $namespace
}

# Wait for the green deployment to be ready
wait_for_deployment $NAMESPACE "green"

# Update the service to point to the green deployment
# Assuming that the service switches between blue and green via a label selector
kubectl patch service $SERVICE -n $NAMESPACE -p '{"spec": {"selector": {"app": "green"}}}'

# Check if the service is reachable
# This assumes you know the external URL or IP to access the service
SERVICE_URL=$(kubectl get service $SERVICE -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Function to check service availability
check_service() {
  local url=$1
  echo "Checking service availability at $url..."
  if curl --fail -s $url > /dev/null; then
    echo "Service is reachable."
  else
    echo "Service is not reachable. Exiting..."
    exit 1
  fi
}

# Check service availability
check_service "http://$SERVICE_URL"

echo "Green deployment successful and service is reachable."