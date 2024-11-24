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

price feed mock 0x0f16525440EefC7C1d10AF8171EC2618A7B134bb
access manager 0x7A2198D87fFbF40f40A63Bf975D4CCF9da5bC0D7
rupio 0x0f16525440EefC7C1d10AF8171EC2618A7B134bb
price feed 0x34e101d3d7945F823559436c5cbcFDe44d7e87C4
collateral safe keep 0x27261581608B1fa22d68c55a70D975A4897F64EE

### Other Testnets

rupio op sepolia 0xDDd2e2A0434cb9B11bC778908bc9335f616f6362
rupio eth sepolia 0xbb9ac7b4973eC691bE01DD4b0B7659a77A53fe23

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
