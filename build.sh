#!/bin/bash
# Copyright (c) 2022 The Pastel Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or https://www.opensource.org/licenses/mit-license.php.

echo Building templates...
python3 scripts/build_templates.py
echo ...done

echo Building docker image for cnode...
sudo docker build --pull --rm -f ".docker/Dockerfile.cnode" -t pastel-cnode:latest ".docker"
echo ...done

echo Fetching .pastel-params...
python3 scripts/fetch_params.py
echo ...done

echo Deploying Pastel network to the Kubernetes cluster...
sudo kubectl delete -f .k8s/pastel-kube.deployment.yaml
sudo kubectl apply -f .k8s/pastel-kube.deployment.yaml
echo ...done

echo Waiting for deployment rollout...
#while [[ $(kubectl get pods -l app=Pastel -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; 
#do 
#  echo "." && sleep 1; 
#done
sleep 30
sudo kubectl get all -o wide
