require("@nomiclabs/hardhat-waffle");
require("dotenv");
require("hardhat-deploy");

module.exports = {
  solidity: "0.8.19",

  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 31337,
    },
    mumbai: {
      url: "https://polygon-mumbai.g.alchemy.com/v2/KgBmkZn1F2u4qzzE5bvpTVl2OMloFFGg",
    },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
};
