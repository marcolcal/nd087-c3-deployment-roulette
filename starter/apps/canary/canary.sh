#!/bin/bash

#DEPLOY_INCREMENTS=2

function manual_verification {
  read -p "Continue deployment? (y/n) " answer

    if [[ $answer =~ ^[Yy]$ ]] ;
    then
        echo "continuing deployment"
    else
        exit
    fi
}

function canary_deploy {
  NUM_OF_V1_PODS=$(kubectl get pods -n udacity | grep -c canary-v1)
  echo "V1 PODS: $NUM_OF_V1_PODS"
  NUM_OF_V2_PODS=$(kubectl get pods -n udacity | grep -c canary-v2)
  echo "V2 PODS: $NUM_OF_V2_PODS"
  # Scale up version 2 to the target number of pods
  # Calculate target number for 50% replacement by version 2
  TARGET_V2_PODS=$((NUM_OF_V1_PODS / 2))
  # Start scaling process
  echo "Current V1 PODS: $NUM_OF_V1_PODS"
  echo "Target V2 PODS: $TARGET_V2_PODS"
  
  #kubectl scale deployment canary-v2 --replicas=$((NUM_OF_V2_PODS + $DEPLOY_INCREMENTS))
  kubectl scale deployment canary-v2 --replicas=$TARGET_V2_PODS -n udacity
  
  #kubectl scale deployment canary-v1 --replicas=$((NUM_OF_V1_PODS - $DEPLOY_INCREMENTS))
  # Scale down version 1 to maintain overall capacity
  NEW_V1_PODS=$((NUM_OF_V1_PODS - TARGET_V2_PODS))
  kubectl scale deployment canary-v1 --replicas=$NEW_V1_PODS -n udacity
  
  # Check deployment rollout status every 1 second until complete.
  ATTEMPTS=0
  ROLLOUT_STATUS_CMD="kubectl rollout status deployment/canary-v2 -n udacity"
  until $ROLLOUT_STATUS_CMD || [ $ATTEMPTS -eq 60 ]; do
    $ROLLOUT_STATUS_CMD
    ATTEMPTS=$((attempts + 1))
    sleep 1
  done
  #echo "Canary deployment of $DEPLOY_INCREMENTS replicas successful!"
  echo "Canary deployment of $TARGET_V2_PODS replicas successful!"
}

# Initialize canary-v2 deployment
kubectl apply -f canary-v2.yml

sleep 1
# Begin canary deployment
while [ $(kubectl get pods -n udacity | grep -c canary-v1) -gt 0 ]
do
  canary_deploy
  manual_verification
done

echo "Canary deployment of v2 successful"
