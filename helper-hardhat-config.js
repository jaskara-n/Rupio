const { ethers } = require("hardhat");

const networkConfig = {
  default: {
    name: "mumbai",
  },

  31337: {
    name: "mumbai",
    CIP: 150n,
    baseRiskRate: 200n,
    riskPremiumRate: 7n,
  },
};

module.exports = {
  networkConfig,
};
