const { ethers } = require("hardhat");
const { expect } = require("chai");
const chainId = 31337;

const object = async function () {
  const { deployments, getNamedAccounts } = hre;
  const main = await ethers.getContract("CollateralSafekeep");
  const riskPremiumRate = await main.getRiskPremiumRate();
  console.log(riskPremiumRate);
};

object();
