const { deployments, getNamedAccounts, deploy } = require("hardhat");
const { ethers } = require("hardhat");
const { networkConfig } = require("../helper-hardhat-config");

const deployCsk = async function () {
  const chainId = 31337;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  console.log("deploying...");

  const indai = await ethers.getContract("Indai");
  const pricefeed = await ethers.getContract("PriceFeed");

  const arguments = [
    networkConfig[chainId].CIP,
    networkConfig[chainId].baseRiskRate,
    networkConfig[chainId].riskPremiumRate,
    indai.target,
    pricefeed.target,
  ];

  const tx = await deploy("CollateralSafekeep", {
    from: deployer,
    args: arguments,
    log: true,
  });

  const deployedContract = await deployments.get("CollateralSafekeep");
  console.log("CollateralSafekeep deployed on mumbai");
  console.log(deployedContract.address);

  const obj2 = await ethers.getContractAt(
    "CollateralSafekeep",
    deployedContract.address,
    deployer
  );

  return obj2;
};

deployCsk();

module.exports = { deployCsk };
deployCsk.tags = ["CollateralSafekeep"];
