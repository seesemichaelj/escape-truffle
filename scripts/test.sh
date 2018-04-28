#!/usr/bin/env bash

# --------------------------------------------------------------------------------------------------
# This script adapted from openzeppelin-solidity's test launch scripts
# Source: (https://github.com/OpenZeppelin/openzeppelin-solidity/scripts/)
# --------------------------------------------------------------------------------------------------

# Exit as soon as a command fails.
set -o errexit

# Executes cleanup function at script exit.
trap cleanup EXIT

cleanup() {
  # Kill the client we started (if we started one and if it's still running).
  if [ -n "$CLIENT_PID" ] && ps -p "$CLIENT_PID" > /dev/null; then
    kill -9 "$CLIENT_PID"
  fi
}

# Set client port
# NB: change geth's port to 8546 when we start using web3 1.0:
if [ "$NETWORK" = "GETH" ]; then
  PORT=8545
fi

if [ "$NETWORK" = "GANACHE" ]; then
  PORT=8547
fi

# Client detection
client_running() {
  nc -z localhost "$PORT"
}

# Client runner
start_client() {
  if [ "$NETWORK" = "GETH" ]; then
    docker run \
      -v /"$PWD"/scripts:/scripts \
      -d \
      -p "$PORT":"$PORT" \
      -p 30303:30303 \
      ethereum/client-go:v1.8.6 \
      --rpc \
      --rpcaddr '0.0.0.0' \
      --rpcport "$PORT" \
      --rpccorsdomain '*' \
      --nodiscover \
      --dev \
      --dev.period 1 \
      --targetgaslimit '8000000' \
      js ./scripts/geth-accounts.js \
      > /dev/null &

      echo "Pausing for 30s to complete client launch."
      sleep 30
  else
    node_modules/.bin/ganache-cli --noVMErrorsOnRPCResponse > /dev/null &
  fi

  CLIENT_PID=$!
}

if client_running; then
  echo "Using existing $NETWORK client on port: $PORT"
else
  echo "Starting $NETWORK client on port: $PORT"
  start_client
fi

node_modules/.bin/truffle test --network "$NETWORK"