#!/bin/bash
set -eux
# your baseledger binary name
BIN=baseledgerd

CHAIN_ID="baseledger"

NODES=2

ALLOCATION="10000000000stake,10000000000worktoken"

# first we start a genesis.json with validator 1
# validator 1 will also collect the gentx's once gnerated
BASELEDGER_HOME="--home /validator"
STARTING_VALIDATOR_CONTAINER="baseledger-validator-container"
docker exec $STARTING_VALIDATOR_CONTAINER $BIN init $BASELEDGER_HOME validator --chain-id=$CHAIN_ID


## Modify generated genesis.json to our liking by editing fields using jq
## we could keep a hardcoded genesis file around but that would prevent us from
## testing the generated one with the default values provided by the module.

# add in denom metadata for both native tokens
docker exec baseledger-validator-container jq '.app_state.bank.denom_metadata += [{"name": "Work Token", "symbol": "WRK", "base": "worktoken", "description": "A test token for paying work", "denom_units": [{"denom": "worktoken", "exponent": 0}]},{"name": "Stake Token", "symbol": "STK", "base": "stake", "description": "A staking test token", "denom_units": [{"denom": "stake", "exponent": 0}]}]' /validator/config/genesis.json > /metadata-genesis.json
docker cp /metadata-genesis.json $STARTING_VALIDATOR_CONTAINER:/metadata-genesis.json

# a 60 second voting period to allow us to pass governance proposals in the tests
docker exec $STARTING_VALIDATOR_CONTAINER jq '.app_state.gov.voting_params.voting_period = "60s"' /metadata-genesis.json > /edited-genesis.json
docker cp /edited-genesis.json $STARTING_VALIDATOR_CONTAINER:/edited-genesis.json

docker exec $STARTING_VALIDATOR_CONTAINER mv /edited-genesis.json /genesis.json

# Copy genesis from starting node to host machine for gentx generation
docker cp $STARTING_VALIDATOR_CONTAINER:/validator/config/genesis.json .

# Sets up an arbitrary number of validators on a single machine by docker exec-ing on respective containers

# First the starting validator TODO: Move to loop
ARGS="$BASELEDGER_HOME --keyring-backend test"

# Generate a validator key, orchestrator key for each validator
docker exec $STARTING_VALIDATOR_CONTAINER $BIN keys add $ARGS validator 2>> /validator-phrases
docker exec $STARTING_VALIDATOR_CONTAINER $BIN keys add $ARGS orchestrator 2>> /orchestrator-phrases

VALIDATOR_KEY=$(docker exec $STARTING_VALIDATOR_CONTAINER $BIN keys show validator -a $ARGS)
ORCHESTRATOR_KEY=$(docker exec $STARTING_VALIDATOR_CONTAINER $BIN keys show orchestrator -a $ARGS)

# move the genesis in
docker cp ./genesis.json $STARTING_VALIDATOR_CONTAINER:/validator/config/genesis.json

docker exec $STARTING_VALIDATOR_CONTAINER $BIN add-genesis-account $ARGS $VALIDATOR_KEY $ALLOCATION
docker exec $STARTING_VALIDATOR_CONTAINER $BIN add-genesis-account $ARGS $ORCHESTRATOR_KEY $ALLOCATION

# move the genesis back out
docker cp $STARTING_VALIDATOR_CONTAINER:/validator/config/genesis.json .

# Then the rest of validators
for i in $(seq 1 $NODES);
do
ARGS="$BASELEDGER_HOME --keyring-backend test"

# Generate a validator key, orchestrator key for each validator
docker exec $STARTING_VALIDATOR_CONTAINER$i $BIN keys add $ARGS validator 2>> /validator-phrases
docker exec $STARTING_VALIDATOR_CONTAINER$i $BIN keys add $ARGS orchestrator 2>> /orchestrator-phrases

VALIDATOR_KEY=$(docker exec $STARTING_VALIDATOR_CONTAINER$i $BIN keys show validator -a $ARGS)
ORCHESTRATOR_KEY=$(docker exec $STARTING_VALIDATOR_CONTAINER$i $BIN keys show orchestrator -a $ARGS)

# move the genesis in
docker cp ./genesis.json $STARTING_VALIDATOR_CONTAINER$i:/validator/config/genesis.json

docker exec $STARTING_VALIDATOR_CONTAINER$i $BIN add-genesis-account $ARGS $VALIDATOR_KEY $ALLOCATION
docker exec $STARTING_VALIDATOR_CONTAINER$i $BIN add-genesis-account $ARGS $ORCHESTRATOR_KEY $ALLOCATION

# move the genesis back out
docker cp $STARTING_VALIDATOR_CONTAINER$i:/validator/config/genesis.json .

done


for i in $(seq 1 $NODES);
do
# move the genesis in
docker cp ./genesis.json $STARTING_VALIDATOR_CONTAINER$i:/validator/config/genesis.json

ARGS="$BASELEDGER_HOME --keyring-backend test"
ORCHESTRATOR_KEY=$(docker exec $STARTING_VALIDATOR_CONTAINER$i $BIN keys show orchestrator -a $ARGS)

docker exec $STARTING_VALIDATOR_CONTAINER$i $BIN gentx $ARGS $BASELEDGER_HOME --moniker validator --chain-id=$CHAIN_ID validator 500000000stake

# copy gentx files to starting validator
if [ $i -gt 0 ]; then
docker cp $STARTING_VALIDATOR_CONTAINER$i:/validator/config/gentx .
docker cp ./gentx $STARTING_VALIDATOR_CONTAINER:/validator/config/
fi
done

# move the genesis in to starting validator
docker cp ./genesis.json $STARTING_VALIDATOR_CONTAINER:/validator/config/genesis.json

# collect gentxs in starting validator
docker exec $STARTING_VALIDATOR_CONTAINER $BIN collect-gentxs $BASELEDGER_HOME
GENTXS=$(docker exec $STARTING_VALIDATOR_CONTAINER ls /validator/config/gentx | wc -l)

# move the genesis out
docker cp $STARTING_VALIDATOR_CONTAINER:/validator/config/genesis.json .

echo "Collected $GENTXS gentx"

rm -rf ./gentx

echo "Cleaned host gentx folder"

# put the now final genesis.json into the correct folders of each validator container
# First the starting validator TODO: Move to loop
docker cp ./genesis.json  $STARTING_VALIDATOR_CONTAINER:/validator/config/genesis.json

# # Then the rest of validators
for i in $(seq 1 $NODES);
do
docker cp ./genesis.json  $STARTING_VALIDATOR_CONTAINER$i:/validator/config/genesis.json
done

rm ./genesis.josn

echo "Cleaned host genesis file"
