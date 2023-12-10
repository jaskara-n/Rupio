const { deployments, getNamedAccounts, deploy } = require("hardhat");

const deployFunc = async function (hre) {
  console.log("deploying...");
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const tx = await deploy("PriceFeed", {
    from: deployer,
    args: [],
    log: true,
  });
  console.log("mumbai deployment address is : ");
  console.log(tx.address);
};

deployFunc();

module.exports = deployFunc;
deployFunc.tags = ["priceFeed"];
