#!/bin/bash

# Pastel data directory (-datadir)
PASTELDIR=$PWD
PASTEL_CLIENT="$PASTELDIR/pastel-cli -datadir=$PASTELDIR"

# Pastel configuration file
PASTEL_CONF=pastel.conf
# get serviceaccount token to access k8s api-server
KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
# cnode rpc port
RPC_PORT=${RPC_PORT}
COMM_PORT=${COMM_PORT}
REGTEST_BLOCK_COUNT=300
REGTEST_BLOCK_INC=25

# get local IP address
IP=$(hostname -i)

# give node some time to initialize
echo "Waiting for blockchain initialization..."
sleep 20
echo "...done"
network="${PASTEL_NETWORK}"
nodetype=${PASTEL_NODE_TYPE}
if [[ "$network" == "regtest" && "$nodetype" == "cnode-miner" ]]; then
    # make sure we have a specified number of blocks in regtest mode
    nBlockCount=$(${PASTEL_CLIENT} getblockcount)
    echo "Miner node should have ${REGTEST_BLOCK_COUNT} blocks, current: $nBlockCount"
    while (( nBlockCount < REGTEST_BLOCK_COUNT ))
    do
        echo "Generating ${REGTEST_BLOCK_INC} blocks"
        txids=$(${PASTEL_CLIENT} generate ${REGTEST_BLOCK_INC})
        echo $txids
        nBlockCount=$(${PASTEL_CLIENT} getblockcount)
        echo "Block count: $nBlockCount"
        sleep 5
    done
fi

while true
do
    # getting IPs of all running PODs in a cluster
    iplist=`curl -sSk -H "Authorization: Bearer $KUBE_TOKEN" https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/default/pods | jq -r '.items[].status.podIP'`
    for ip in $iplist; do
    # skip this pod IP
    if [[ -z "$ip" || "$ip" == "$IP" ]]; then
        continue
    fi
    node_str="addnode=$ip:$COMM_PORT"
    isIpDefined=`grep $node_str "${PASTEL_CONF}"`
    if [[ -z "$isIpDefined" ]]; then
        output=`${PASTEL_CLIENT} addnode "$ip:$COMM_PORT" "add"`
        if [[ "$output" == *"error"* ]]; then
           if [[ "$output" == *"error code: -28"* ]]; then
             echo "  node is still initializing..."
           else
             echo "  failed to add node [$ip], will try again..."
           fi
        else
          echo "Adding node [$ip]"
          echo $node_str >> "${PASTEL_CONF}"
        fi
    fi
    done

    sleep 30
done
echo "pod-monitor exiting"
