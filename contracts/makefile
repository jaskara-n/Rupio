-include .env
build:; forge build
test contracts:; forge test
deploy on optimism sepolia:
	forge script script/Deploy.s.sol --rpc-url $(OPTIMISM_SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvv
deploy on base sepolia:
		forge script script/Deploy.s.sol --rpc-url $(BASE_SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_BASE_API_KEY) -vvv
