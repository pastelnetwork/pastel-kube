#!/bin/bash
touch /tmp/healthy

ulimit -c unlimited

# Pastel data directory (-datadir)
PASTELDIR=$PWD
# Pastel debug log categories:
#   addrman, alert, bench, coindb, db, estimatefee, http, libevent, lock, mempool, net, partitioncheck, pow, proxy, prune,
#   rand, reindex, rpc, selectcoins, tor, zmq, zrpc, zrpcunsafe (implies zrpc), compress
# PASTEL_DEBUG 
# Additional parameters that will be passed while staring cnode
# PASTEL_EXTRA_PARAMS
# Pastel configuration file
PASTEL_CONF=pastel.conf
USERDIR=/root
nodetype=${PASTEL_NODE_TYPE}

# get local IP address
IP=$(hostname -i)
echo "POD IP: $IP"

# check network value
network="${PASTEL_NETWORK}"
bMainNet=0
case "$network" in
  regtest)
    ;;
 
  mainnet)
    bMainNet=1
    ;;
 
  testnet)
    ;;

  *)
    echo "ERROR! Not supported network name: $network"
    exit 1
    ;;
esac

# check Pastel data directory
echo "Current Pastel data directory: $PASTELDIR"
if [[ -z "$network" ]]; then
  echo "PASTEL_NETWORK environment variable is not defined"
  exit 2
fi

# archive filename with prepackaged blockchain data
chaincopy_archive=$USERDIR/.pastel-params/chain-${network}.tar.gz
# file to check that archive was extracted and the network is configured
chaincopy_extracted=$PASTELDIR/.${network}_chain_extracted

if [[ ! -f ${chaincopy_extracted} ]]; then
  bChainArchiveExists=0
  if [[ -f ${chaincopy_archive} ]]; then
    echo "Extracting blockchain data from ${chaincopy_archive}..."
    # extract prepackaged network blockchain data
    tar xvfz ${chaincopy_archive}
    echo "Blockchain archive [${chaincopy_archive}] successfully extracted"
    bChainArchiveExists=1
  fi
  # we can skip archive only if we are on testnet or regtest
  if (( $bChainArchiveExists==0 && $bMainNet==1 )); then
    echo "Cannot find blockchain archive: ${chaincopy_archive}"
    exit 3
  fi
  # mark - extraction completed
  touch "${chaincopy_extracted}"
fi

# configure option in pastel.conf
# parameters:
#   $1 - option name
#   $2 - option value
function set_conf_option()
{
  local optstr="$1=$2"
  local isValueDefined=`grep "$optstr" "${PASTEL_CONF}"`
  if [[ -z "$isValueDefined" ]]; then
    echo "$optstr" >> "${PASTEL_CONF}"
    echo "Option [$optstr] is configured in ${PASTEL_CONF}"
  fi
}

# check if network is already configured in the configuration file
set_conf_option ${network} 1
#set_conf_option "rpcbind" $IP

# configure miner
if [[ "$nodetype" == "cnode-miner" ]]; then
  set_conf_option "gen" 1
fi

echo "Starting POD monitor..."
./pod-monitor.sh &

echo "Starting Pastel node..."
echo ./pasteld -discover=1 -externalip=$IP -whitelist=0.0.0.0/0 -debug=${PASTEL_DEBUG} ${PASTEL_EXTRA_PARAMS} -datadir=$PASTELDIR
./pasteld -discover=1 -externalip=$IP -whitelist=0.0.0.0/0 -debug=${PASTEL_DEBUG} ${PASTEL_EXTRA_PARAMS} -datadir=$PASTELDIR

