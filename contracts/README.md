## Architecture Diagram

![Blank diagram](https://github.com/user-attachments/assets/e84af58a-7e70-4577-903f-e0555224cc04)

## Contracts Architecture

### CollateralSafekeep

- Manages vault for each user, allows users to lock/update ETH balance, withdrawals and protect liquidation.
- Allows users to mint rupio cross-chain or on home chain, if they have over-collateral locked in their vault.
- Integrated with AccessManager to restrict mod/admin only functions and monitor contract.
- Integrated with Chainlink automation to periodically calculate vault health of all vaults.
- Chainlink automation is used because for looping through all the vaults for vault health updation would be costly executing on-chain so we have chainlink as a saviour.
- Manages liquidations of vaults if vault health too low.
- Integrated with openzeppelin ownable and re-entrancy guard for security purposes.
- This contract is the foundational contract for RupioDao, all de-fi maths is encapsulated in this contract.

### PriceFeed

- Provides required ETH/USD and INR/USD prices to CollateralSafekeep contract for maintaining the peg.
- Integrated with Chainlink PriceFeeds for reliable oracle data.

### OracleLib

- A simple library contract to stale check the chainlink pricefeeds before sending over data to CollateralSafekeep.
- Stake checking means to check if the price is latest, or dormant.
- This library is used by the CollateralSafekeep contract to call PriceFeed contract.

### Rupio

- Token contract for Rupio token, which maintains its peg on 1 INR always.
- Integrated with LayerZero cross-chain solutions to make Rupio token cross-transferable and mintable.
- AccessManager restricts minting of Rupio tokens without access.

### AccessManager

- An admin contract that allows adding of more moderators, revoking roles, granting minter and mod roles.
- This contract is used to restrict certain moderator-only functions all over the contracts of RupioDao.

### RupioSavingsContract

- This contract allows users to lock their Rupio tokens and earn intrest on them.
- This is used as a RupioDao incentivizing protocol for situations where Rupio tokens are needed to be circulated.

### Governance

- This contract allows stake-holders or investors to participate in governance decisions, for example setting intrest rates, ratios, thresholds and platform fees.

## Deployed contract addresses (Verified on blockscout)

### Base Sepolia

- PriceFeedMock
  https://base-sepolia.blockscout.com/address/0xC038798eAF9f3eCd73AC5C6A5e7AF8ED2483553B
- AccessManager.sol
  https://base-sepolia.blockscout.com/address/0x1cc5e98a5222891e0ba2e29abcb6f95fe8f41dc9
- Rupio.sol
  https://base-sepolia.blockscout.com/token/0x9BD90ac5435a793333C2F1e59A6e7e5dBAd0AFEa
- PriceFeed.sol
  https://base-sepolia.blockscout.com/address/0x3f0ca799102e648cfceb4830fb5401421d145f44
- CollateralSafekeep.sol
  https://base-sepolia.blockscout.com/address/0x2F15F0B2492694d65824C71aa41DDc848cb47614

### Other Testnets

rupio op sepolia 0xDDd2e2A0434cb9B11bC778908bc9335f616f6362
rupio eth sepolia 0xbb9ac7b4973eC691bE01DD4b0B7659a77A53fe23

## Frameworks and Tools used

- Foundry : For testing and deployment
- Chainlink Automation : For periodically updating vault health of all vaults.
- Chainlink Pricefeeds : For providing price rates from oracles
- LayerZero : For making Rupio token cross-chain compatible
- OpenZeppelin : Used in governance contract, and allover the system for ownable, time-locks and such

## Local Cloning Instructions

### Clone the repository and forge install

```
git clone https://github.com/jaskara-n/Rupio.git
```

```
forge install
```

### Add .env file

```env
BASE_SEPOLIA_RPC_URL=""
OP_SEPOLIA_RPC_URL=""
ETH_SEPOLIA_RPC_URL=""
PRIVATE_KEY=""
```

### Check Makefile, and Explore!

```
//feel free to run some forge tests, on local as well as forks, run scripts to deploy the dynamite!
```
## Forge Coverage
<img width="801" alt="Screenshot 2024-11-25 at 1 12 54 PM" src="https://github.com/user-attachments/assets/455ca8c4-b019-40e1-a27d-9f031cb11e69">
- Main contracts are thoroughly tested, including fuzz tests.

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
