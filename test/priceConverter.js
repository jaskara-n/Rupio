import { expect } from "chai";
import { ethers } from "hardhat";
const PriceConverter = await ethers.deployContract("priceConverter");

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
