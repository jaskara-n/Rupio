const { deployments, getNamedAccounts } = require("hardhat");

const deployFunc = async function (hre) {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  await deploy("priceConverter", {
    from: deployer,
    args: [],
    log: true,
  });
};

module.exports = { deployFunc };
func.tags = ["priceConverter"];
