require("@nomiclabs/hardhat-waffle");
require("dotenv").config();
require("ethers");
require("@nomiclabs/hardhat-ethers");
require("hardhat-deploy");
require("hardhat-deploy-ethers");

const MUMBAI_RPC_URL = process.env.MUMBAI_RPC_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;

module.exports = {
  solidity: "0.8.19",

  defaultNetwork: "mumbai",
  networks: {
    hardhat: {
      chainId: 31337,
    },
    mumbai: {
      url: MUMBAI_RPC_URL,
      accounts: [PRIVATE_KEY],
      chainId: 80001,
    },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
};
