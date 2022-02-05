@echo off
rem Copyright (c) 2022 The Pastel Core developers
rem Distributed under the MIT software license, see the accompanying
rem file COPYING or https://www.opensource.org/licenses/mit-license.php.

echo Building templates...
wsl python3 scripts/build_templates.py
echo ...done

echo Building docker image for cnode...
docker build --pull --rm -f ".docker/Dockerfile.cnode" -t pastel-cnode:latest ".docker"
echo ...done

echo Fetching .pastel-params...
wsl python3 scripts/fetch_params.py
echo ...done

echo Deploying Pastel network to the Kubernetes cluster...
kubectl delete -f .k8s/pastel-kube.deployment.yaml
kubectl apply -f .k8s/pastel-kube.deployment.yaml
echo ...done

echo Waiting for deployment rollout...
timeout 30
kubectl get all -o wide