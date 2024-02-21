const { deployments, getNamedAccounts, deploy } = require("hardhat");
const { ethers } = require("hardhat");

const deployIndai = async function (hre) {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  console.log("deploying...");

  const tx = await deploy("Indai", {
    from: deployer,
    args: [],
    log: true,
  });

  const deployedContract = await deployments.get("Indai");

  const obj0 = await ethers.getContractAt(
    "Indai",
    deployedContract.address,
    deployer
  );

  console.log("Indai deployed on mumbai");
  console.log(deployedContract.address);

  return obj0;
};

deployIndai();
module.exports = { deployIndai };
deployIndai.tags = ["Indai"];
