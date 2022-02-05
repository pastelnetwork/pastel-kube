#!/bin/bash
# Copyright (c) 2022 The Pastel Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or https://www.opensource.org/licenses/mit-license.php.

echo "Pastel Network Packager"
echo
if [[ $# -eq 0 ]]; then
  echo "ERROR! Required parameter 'network' is missing"
  echo "./packnet.sh [network] [packmode_bitmask]"
  echo "  [network] - mainnet, testnet or regtest"
  echo "  [packmode_bitmask] - pack modes (bitmask)"
  echo "    1 - pack blockchain database only"
  echo "    2 - pack node-specific files"
  echo "    3 - 1 + 2"
  exit 1
fi

network=$1
nPackMode=3
if [[ $# -gt 0 ]]; then
  network=$1
fi

if [[ $# -gt 1 ]]; then
  nPackMode=$2
fi

# process network type
packrootdir=
bMainNet=false
case "$network" in
  regtest)
    packrootdir="regtest"
    ;;
 
  mainnet)
    packrootdir=
    bMainNet=true
    ;;
 
  testnet)
    packrootdir="testnet3"
    ;;

  *)
    echo "ERROR! Not supported network name: $network"
    exit 2
    ;;
esac

if [[ $bMainNet == false ]]; then
  if [ ! -d "$packrootdir" ]; then
    echo "ERROR! network root directory [$packrootdir] does not exist"
    exit 1
  fi
  packrootdir+=/
fi

if (( nPackMode & 1 )); then
  echo "Packing network [$network] blockchain database files..."
  tar cvfz chain-$network.tar.gz \
    "${packrootdir}blocks" \
    "${packrootdir}chainstate" \
    "${packrootdir}database" \
    "${packrootdir}tickets"
  echo "...done"
fi
if (( nPackMode & 2 )); then
  echo "Packing network [$network] site-specific files..."
  tar cvfz chain-$network-node.tar.gz \
    "${packrootdir}pastelkeys" \
    "${packrootdir}wallet.dat" \
    "${packrootdir}fee_estimates.dat" \
    "${packrootdir}masternode.conf"
  echo "...done"
fi
