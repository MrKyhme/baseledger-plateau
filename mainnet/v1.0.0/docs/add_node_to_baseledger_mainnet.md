# ADD NODE TO BASELEDGER MAINET


## Preparing

1.  Prepare a https://pro.coinmarketcap.com/ API token. Free plan is ok for now.
2.  Prepare a https://www.coinapi.io/ API token. Free plan is ok for now.
3.  Prepare a https://infura.io/product/ethereum RPC url. Free plan is ok for now.
4.  Copy the mainnet/v1.0.0 folder from the repo to your node
5.  Navigate to mainnet/v1.0.0/docs on the node
6.  Execute `chmod +x prereqs.sh` and then `bash prereqs.sh`

Note: IP addresses of the other nodes will be communicated to you by the council. These must be allowed in the firewall rules of your host machine under port 26656. All other incoming connections should be disabled.

## Setting up accounts

7.  Navigate to /root/.baseledger/cosmovisor/genesis/bin
8.  Run */root/.baseledger/cosmovisor/genesis/bin/baseledgerd init validator --chain-id=baseledger*
9.  Replace the /root/.baseledger/config/genesis.json with mainnet/v1.0.0/genesis.json
10.  Run */root/.baseledger/cosmovisor/genesis/bin/baseledgerd keys add --keyring-backend file validator* and store address and  mnemonic in a safe place
    10.1 You will be asked to create a keyring-backend password. Make sure to write a strong password and save it somewhere safe
11. Run */root/.baseledger/cosmovisor/genesis/bin/baseledgerd keys add --keyring-backend file orchestrator* and store address and mnemonic in a safe place

## Requesting tokens

12. Request 1 work token for orchestrator address and staking tokens for validator address by following the step 4 from ./running_a_node_start_here.md. You will not be able to execute step 24 as well as steps after step 26 until you receive the tokens.

## Starting the node

14. Adjust the mainnet/v1.0.0/baseledger/cosmovisor.service by adding your node ip here *--p2p.laddr tcp://<your_node_ip>:26656*
15. Adjust the mainnet/v1.0.0/baseledger/cosmovisor.service by adding your keyring password here *Environment=KEYRING_PASSWORD=<your_keyring_password>*
16. Copy the adjusted mainnet/v1.0.0/baseledger/cosmovisor.service to /etc/systemd/system
17. Adjust the mainnet/v1.0.0/orchestrator/orchestrator.service by adding your infura url here *--ethereum-rpc=<your_infura_url>*
18. Adjust the mainnet/v1.0.0/orchestrator/orchestrator.service by adding your Coin market cap api token here *Environment=COINMARKETCAP_API_TOKEN=<your_coinmarketcap_api_token>*
19. Adjust the mainnet/v1.0.0/orchestrator/orchestrator.service by adding your Coin api api token here *Environment=COINAPI_API_TOKEN=<your_coin_api_token>*
20. Copy the adjusted mainnet/v1.0.0/orchestrator/orchestrator.service to /etc/systemd/system
21. Run *systemctl daemon-reload*
22. Run *systemctl start cosmovisor*
23. Verify by running *systemctl status cosmovisor* and *journalctl -u cosmovisor*

## Registering as a validator

24. After tokens received, run */root/.baseledger/cosmovisor/genesis/bin/baseledgerd tx staking create-validator --amount=2000000stake --pubkey=$(/root/.baseledger/cosmovisor/genesis/bin/baseledgerd tendermint show-validator) --moniker=<your_moniker> --commission-rate="0" --commission-max-rate="0" --commission-max-change-rate="0" --min-self-delegation="2000000" --from=validator --yes --keyring-backend file*. your_moniker is the name of the node which will be visible through the explorer ("node_xyz", "org_node", "mars"). You will be prompted to enter the keyring pasword you defined in step 10. Enter it!
25. Verify your validator is added by performing */root/.baseledger/cosmovisor/genesis/bin/baseledgerd query staking validators*

## Starting the oracle

26. Navigate to /root/.baseledger/orchestrator
27. Run */root/.baseledger/orchestrator/baseledger_bridge init*
28. Run */root/.baseledger/orchestrator/baseledger_bridge keys set-orchestrator-key --phrase="<orchestrator_mnemonic>"*. Prepare the command in a text editor and replace <orchestrator_mnemonic>  with the mnemonic you stored when executing step 11.
29. Run */root/.baseledger/orchestrator/baseledger_bridge keys register-orchestrator-address --validator-phrase="<validator_mnemonic>"*. Prepare the command in a text editor and replace <validator_mnemonic>  with the mnemonic you stored when executing step 10.
30. Run *systemctl start orchestrator*
31. Verify service active by running *systemctl status orchestrator* and *journalctl -u orchestrator*
