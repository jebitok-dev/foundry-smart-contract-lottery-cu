``````
$ forge coverage --report debug > coverage.txt
$ forge test --mt testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue
$ forge test --mt testPerformUpkeepRevertsIfCheckUpkeepIsFalse
$ forge test --mt testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId
$ anvil 
$ forge build
$ forge test
$ forge test --fork-url $SEPOLIA_RPC_URL
$ forge script DeployRaffle --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
$ forge test --debug
$ forge test --debug testRaffleRecordsPlayerWhenTheyEnter
``````
