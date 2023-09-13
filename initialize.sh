#!/bin/bash

set -e

TOKEN_ADMIN="GDT2NORMZF6S2T4PT4OBJJ43OPD3GPRNTJG3WVVFB356TUHWZQMU6C3U"
TOKEN_ADMIN_IDENTIFIER="AAAABAAAAAEAAAAAAAAAAgAAAAUAAAAHQWNjb3VudAAAAAAEAAAAAQAAAAgAAAAA56a6LMl9LU+PnxwUp5tzx7M+LZpNu1alDvvp0PbMGU8="

case "$1" in
standalone)
  echo "Using standalone network"
  export SOROBAN_RPC_HOST="http://localhost:8000"
  export SOROBAN_RPC_URL="$SOROBAN_RPC_HOST/soroban/rpc"
  export SOROBAN_NETWORK_PASSPHRASE="Standalone Network ; February 2017"
  export SOROBAN_SECRET_KEY="SAKCFFFNCE7XAWYMYVRZQYKUK6KMUCDIINLWISJYTMYJLNR2QLCDLFVT"

  echo STEP 1: Fund token admin account from friendbot
  curl "$SOROBAN_RPC_HOST/friendbot?addr=$TOKEN_ADMIN"
  ;;
futurenet)
  echo "Using Futurenet network"
  export SOROBAN_RPC_HOST="http://localhost:8000"
  export SOROBAN_RPC_URL="$SOROBAN_RPC_HOST/soroban/rpc"
  export SOROBAN_NETWORK_PASSPHRASE="Test SDF Future Network ; October 2022"
  export SOROBAN_SECRET_KEY="SAKCFFFNCE7XAWYMYVRZQYKUK6KMUCDIINLWISJYTMYJLNR2QLCDLFVT"
  # TODO: Use friendbot to fund the token admin, or figure our token admin here...
  echo STEP 1: Fund token admin account from friendbot
  curl "https://friendbot-futurenet.stellar.org/?addr=$TOKEN_ADMIN"
  ;;
""|sandbox)
  # no-op
  ;;
*)
  echo "Usage: $0 sandbox|standalone|futurenet"
  exit 1
  ;;
esac

echo ".."
echo ".."
ARGS="--secret-key $SOROBAN_SECRET_KEY"

echo STEP 2.1: Wrap the Dummy Stellar Asset 1
mkdir -p .soroban
TOKEN_ID_1=$(soroban lab token wrap $ARGS --asset "DUMMY1:$TOKEN_ADMIN")

echo -n "$TOKEN_ID_1" > .soroban/token_id_1
echo "  - Dummy Stellat Asset wrapped with TOKEN_ID_1: $TOKEN_ID_1"

echo ".."
echo ".."

echo STEP 2.2: Wrap the Dummy Stellar Asset 2
TOKEN_ID_2=$(soroban lab token wrap $ARGS --asset "DUMMY2:$TOKEN_ADMIN")
echo -n "$TOKEN_ID_2" > .soroban/token_id_2
echo "  - Dummy Stellat Asset wrapped with TOKEN_ID_2: $TOKEN_ID_2"

echo ".."
echo ".." 

echo STEP 3: Build the soroswap_pair contract
cd contracts
make build 
cd ..

echo ".."
echo ".."

echo STEP 4: Deploy the liquidity_pool contract
LIQUIDITY_POOL_ID="$(
  soroban contract deploy $ARGS\
    --wasm contracts/target/wasm32-unknown-unknown/release/soroban_liquidity_pool_contract.wasm
)"
echo "$LIQUIDITY_POOL_ID" > .soroban/liquidity_pool
echo "Contract deployed succesfully with LIQUIDITY_POOL_ID: $LIQUIDITY_POOL_ID"

echo ".."
echo ".."

echo STEP 5: Install a token contract in order to get the wasm WASM_HASH
TOKEN_WASM_HASH="$(
  soroban contract install $ARGS\
    --wasm contracts/target/wasm32-unknown-unknown/release/soroban_token_contract.wasm
)"

echo "Token contract installed succesfully with TOKEN_WASM_HASH: $TOKEN_WASM_HASH"


echo "$TOKEN_WASM_HASH" > .soroban/token_wasm_hash


echo STEP 4: Initialize the liquidity_pool contract with TOKEN IDs
soroban contract invoke $ARGS \
  --id "$LIQUIDITY_POOL_ID" \
  --fn initialize --\
  -- $TOKEN_WASM_HASH \
  -- "$TOKEN_ID_1" \
  -- "$TOKEN_ID_2" \
  --wasm contracts/target/wasm32-unknown-unknown/release/soroban_liquidity_pool_contract.wasm

 echo "Done"


# soroban invoke \
#   --id "$LIQUIDITY_POOL_ID" \
#   --fn share_id  \
#   --wasm contracts/target/wasm32-unknown-unknown/release/soroban_liquidity_pool_contract.wasm


 LIQUIDITY_POOL_ID=$(cat .soroban/liquidity_pool)
 TOKEN_ID_1=$(cat .soroban/token_id_1)
 TOKEN_ID_2=$(cat .soroban/token_id_2)
 TOKEN_WASM_HASH=$(cat .soroban/token_wasm_hash)



# soroban invoke \
#   --id "$LIQUIDITY_POOL_ID" \
#   --fn share_id  \
#   --wasm contracts/target/wasm32-unknown-unknown/release/soroban_liquidity_pool_contract.wasm
