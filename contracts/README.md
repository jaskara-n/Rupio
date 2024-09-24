# Deployed Contracts on Optimism Sepolia

- **Mock Price Feed for Eth to INR**: https://sepolia-optimism.etherscan.io/address/0x796e40ae27a3737539588f04239f4deb96fc4430
- **Access Manager**: https://sepolia-optimism.etherscan.io/address/0xe1b1b6940c7f7aa80d2f96c5f9349fe23a1d7cb2
- **Price Contract**: https://sepolia-optimism.etherscan.io/address/0xe7817b9f4e692861d80b60c1f48a6ca7a1fa7d79
- **Indai Token Contract**: https://sepolia-optimism.etherscan.io/address/0x9eb7ddb6e4425f78ee217023c93aa6fd96c1d786
- **CollateralSafekeep**: https://sepolia-optimism.etherscan.io/address/0xfaaeadb7f4718956d93ab6c5a2a641fc43404360

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
