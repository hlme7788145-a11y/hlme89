#!/bin/bash
# fetch_bytecode.sh
# Fetch runtime bytecode for a contract address on BSC and save to contracts/<address>_bytecode.txt
# Requires: curl, jq

ADDR="0x9603a3D3dcCCF5ef1A2060A3Da796aC084cC66EB"
OUT="contracts/${ADDR}_bytecode.txt"
RPC="https://bsc-dataseed.binance.org/"

PAYLOAD=$(printf '{"jsonrpc":"2.0","method":"eth_getCode","params":["%s","latest"],"id":1}' "$ADDR")
RESP=$(curl -s -X POST --header "Content-Type: application/json" --data "$PAYLOAD" "$RPC")
BYTECODE=$(echo "$RESP" | jq -r '.result')
if [ "$BYTECODE" = "null" ] || [ -z "$BYTECODE" ]; then
  echo "Error fetching bytecode: $RESP" >&2
  exit 1
fi

echo "$BYTECODE" > "$OUT"
echo "Saved bytecode to $OUT"
