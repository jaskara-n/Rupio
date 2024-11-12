-include .env
build:; forge build
test contracts:; forge test
deploy home chain:
	forge script script/DeployHomeChain.s.sol --rpc-url $(BASE_SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --verifier blockscout --verifier-url $(BASE_SEPOLIA_BLOCKSCOUT) -vvv
deploy rupio on op sepolia:
	forge script script/DeployRupio.s.sol --rpc-url $(OP_SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify  --verifier blockscout  --verifier-url $(OP_SEPOLIA_BLOCKSCOUT) -vvv
deploy rupio on eth sepolia:
	forge script script/DeployRupio.s.sol --rpc-url $(ETH_SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --verifier blockscout  --verifier-url $(ETH_SEPOLIA_BLOCKSCOUT) -vvv
deploy rupio on base sepolia:
	forge script script/DeployRupio.s.sol --rpc-url $(BASE_SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --verifier blockscout  --verifier-url $(BASE_SEPOLIA_BLOCKSCOUT) -vvv
set peer on base sepolia:
	forge script script/SetPeer.s.sol --rpc-url $(BASE_SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast  -vvv
set peer on op sepolia:
	forge script script/SetPeer.s.sol --rpc-url $(OP_SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast  -vvv