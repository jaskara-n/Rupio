const { ethers } = require("hardhat");
const { expect } = require("chai");
const { networkConfig } = require("../helper-hardhat-config");
const chainId = 31337;

const object = async function () {
  const { deployments, getNamedAccounts } = hre;
  const main = await ethers.getContract("CollateralSafekeep");
  return main;
};

describe("CollateralSafekeep contract tests", function () {
  before(async function () {
    main = await object();
  });

  it("should initialise all state variables and push initial vault", async function () {
    const CIP = await main.getCIP();
    expect(CIP).to.equal(networkConfig[chainId].CIP);
    const baseRiskRate = await main.getBaseRiskRate();
    expect(baseRiskRate).to.equal(networkConfig[chainId].baseRiskRate);
    const riskPremiumRate = await main.getRiskPremiumRate();
    expect(riskPremiumRate).to.equal(networkConfig[chainId].riskPremiumRate);
    const currentVaultId = await main.getCurrentVaultId();
    expect(currentVaultId).to.equal(1n);
  });

  it("", async function () {});
});
