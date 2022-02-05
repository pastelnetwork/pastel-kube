# Pastel Kubernetes Deployment

---

This project allows to deploy copy of Pastel blockchain to kubernetes cluster.

## Software prerequisites

### Windows 10, Windows 11

Install the following software:

- Windows Subsystem for Linux (WSL-2)
  Install [WSL-2](https://docs.microsoft.com/en-us/windows/wsl/installhttps:/), default ubuntu distribution:
  ```shell
  wsl --install -u Ubuntu
  ```
- from ubuntu console window:
  ```shell
  sudo apt update
  sudo apt install python3
  ```
- Install [Docker Desktop for Windows](https://docs.docker.com/desktop/windows/install/https:/)
- Enable [Kubernetes](https://docs.docker.com/desktop/kubernetes/https:/) server in Docker Desktop

### Ubuntu Linux 20.04, 21.04 or 21.10

- [Install Docker Engine](https://snapcraft.io/install/docker/ubuntuhttps:/):
  ```shell
  sudo apt update
  sudo snap install docker
  ```
- [Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/https:/):
  ```shell
  sudo snap install kubectl --classic
  ```
- [Install minikube](https://snapcraft.io/install/minikube/ubuntuhttps:/):
  ```shell
  sudo snap install minikube

  ```

## Creating copy of Pastel blockchain

- copy `scripts/packnet.sh` shell script to the root directory of the running Pastel cnode (Ubuntu version only).
- stop cnode:

  ```shell
  ./pastel-cli stop
  ```
- execute packaging script with network type as a parameter (mainnet, testnet or regtest):

  ```shell
  ./packnet.sh mainnet
  ```

  This script will create a copy of blockchain level-db, block index and current chain state to `chain-[network-type].tar.gz` file.
- copy this file to `.pastel-params` folder
- copy "pasteld" and "pastel-cli" binaries to the ./docker/cnode folder

## Deployment configuration

Configure deployment options in `netconfig.txt` file:


| Parameter              | Description                                                                                                                                                                                       |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| network                | network type (mainnet, testnet or regtest)                                                                                                                                                        |
| cnode-count            | number of cnodes to create, default (3)                                                                                                                                                           |
| rpc-port               | rpc port for cnode pods, default (12935)                                                                                                                                                          |
| comm-port              | comm port for cnode pods, default (12930)                                                                                                                                                         |
| rpc-user               | rpc user                                                                                                                                                                                          |
| rpc-password           | rpc password                                                                                                                                                                                      |
| resources-limit-memory | cnode memory resource limit: https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/. Please note, that Pastel mainnet cnode currently requires at least 1500Mi of memory. |
| resources-limit-cpu    | cnode cpu resource limit                                                                                                                                                                          |

## Build and Deploy Pastel network

Execute `build.cmd` on Windows or `build.sh` shell script on Linux:

```shell
./build.sh
```

The script will:

- create dockerfile for cnode from template, k8s templates and Pastel configuration file `pastel.conf` using configuration parameters from `netconfig.txt`
- build docker image for cnode
- fetch Zcash zkSNARK parameters to `.pastel-params` directory. This directory will be mounted in each pod, so these files will be shared across all pods
- deploy to Kubernetes cluster:
  - cnode miner
  - specified number of cnodes
- `.docker/cnode/start-node.sh` is an entrypoint to start cnode in the pod.
- `start-node.sh` script starts `pod-monitor.sh` in the background. This script will:
  - wait for blockchain initialization
  - get periodically list of pods and call `./pastel-cli addnode` to connect new cnodes
    When the network is deployed, cnode pods can communicate only with each other, dnsseed and dns lookups are disabled. Also, rpc ports of the cnodes are not accessible on the host machine.
- To expose rpc port of any cnode:
  - get list of running pods:

```shell
kubectl get pods -o wide
NAME                          READY   STATUS    RESTARTS   AGE    IP         NODE             NOMINATED NODE   READINESS GATES
cnode-765f89b468-cwl6l        1/1     Running   0          4m5s   10.1.1.3   docker-desktop   <none>           <none>
cnode-765f89b468-dxgh8        1/1     Running   0          4m5s   10.1.1.5   docker-desktop   <none>           <none>
cnode-765f89b468-pc9h2        1/1     Running   0          4m5s   10.1.1.4   docker-desktop   <none>           <none>
cnode-miner-d6998b8c9-xmblq   1/1     Running   0          4m5s   10.1.1.6   docker-desktop   <none>           <none>
```

* forward rpc port of the cnode-765f89b468-cwl6l to the host:

```shell
kubectl port-forward pods/cnode-765f89b468-cwl6l 12935:12935
Forwarding from 127.0.0.1:12935 -> 12935
```

This will forward all TCP traffic from localhost:12935 to the pod rpc port 12935.

## Troubleshooting

Find status of deployment and all pods:

```shell
  kubectl get all -o wide
  NAME                              READY   STATUS    RESTARTS   AGE   IP          NODE             NOMINATED NODE   READINESS GATES
  pod/cnode-765f89b468-28fcg        1/1     Running   0          60s   10.1.1.8    docker-desktop   <none>           <none>
  pod/cnode-765f89b468-698hh        1/1     Running   0          60s   10.1.1.7    docker-desktop   <none>           <none>
  pod/cnode-765f89b468-ss68s        1/1     Running   0          60s   10.1.1.9    docker-desktop   <none>           <none>
  pod/cnode-miner-d6998b8c9-ctlqx   1/1     Running   0          60s   10.1.1.10   docker-desktop   <none>           <none>
  
  NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)           AGE     SELECTOR
  service/kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP           9d      <none>
  service/miner-svc    NodePort    10.102.214.162   <none>        12935:32352/TCP   2d21h   app=Pastel,nodeType=miner
  
NAME                          READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS        IMAGES                SELECTOR
deployment.apps/cnode         3/3     3            3           60s   cnode-container   pastel-cnode:latest   app=Pastel
deployment.apps/cnode-miner   1/1     1            1           60s   cnode-container   pastel-cnode:latest   app=Pastel
NAME                                    DESIRED   CURRENT   READY   AGE   CONTAINERS        IMAGES                SELECTOR
replicaset.apps/cnode-765f89b468        3         3         3       60s   cnode-container   pastel-cnode:latest   app=Pastel,pod-template-hash=765f89b468
replicaset.apps/cnode-miner-d6998b8c9   1         1         1       60s   cnode-container   pastel-cnode:latest   app=Pastel,pod-template-hash=d6998b8c9
```

If status of any pod is not Running, you can inspect pod logs:

```shell
kubectl logs pod/cnode-765f89b468-28fcg
POD IP: 10.1.1.12
Current Pastel data directory: /pastel
Extracting blockchain data from [/root/.pastel-params/chain-mainnet.tar.gz]...
blocks/
blocks/blk00001.dat
....
Blockchain archive [/root/.pastel-params/chain-mainnet.tar.gz] successfully extracted
Option [mainnet=1] is configured in pastel.conf
Starting POD monitor...
Starting Pastel node...
./pasteld -discover=1 -externalip=10.1.1.12 -whitelist=0.0.0.0/0 -debug=net,rpc,mempool -txindex=1 -datadir=/pastel
Waiting for blockchain initialization...
...done
Adding node [10.1.1.7]
Adding node [10.1.1.9]
Adding node [10.1.1.10]
```

You can also check pod state and event log:

```shell
kubectl describe pod/cnode-765f89b468-28fcg
```

Visual Studio Code with installed Kubernetes and Docker extensions can help to monitor pods, forward ports, access files, check logs and statuses from UI.

License
-------

For license information see the file [COPYING](COPYING).
