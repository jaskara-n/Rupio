const { deployments, getNamedAccounts, deploy } = require("hardhat");
const { ethers } = require("hardhat");

const deployPriceFeed = async function (hre) {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  console.log("deploying...");

  const tx = await deploy("PriceFeed", {
    from: deployer,
    args: [],
    log: true,
  });

  const deployedContract = await deployments.get("PriceFeed");

  const obj1 = await ethers.getContractAt(
    "PriceFeed",
    deployedContract.address,
    deployer
  );

  console.log("PriceFeed deployed on mumbai");
  console.log(deployedContract.address);

  return obj1;
};

deployPriceFeed();
module.exports = { deployPriceFeed };
deployPriceFeed.tags = ["Indai"];
