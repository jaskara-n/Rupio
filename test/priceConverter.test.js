const { run } = require("hardhat");
const { ethers } = require("hardhat");
const { expect } = require("chai");

async function init() {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const deployFunc = require("../deploy/priceConverter");
  await run("deploy");
  const deployedContract = await deployments.get("PriceFeed");
  const main = await ethers.getContractAt(
    "PriceFeed",
    deployedContract.address,
    deployer
  );
  return main;
}

describe("PriceFeed contract tests", function () {
  let main;
  before(async function () {
    main = await init();
    console.log("test");
  });
  it("should deploy and read from price feed", async function () {
    const result = await main.readDataFeed();
    console.log("result", result);
  });
});
