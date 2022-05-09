import { ethers } from "hardhat";

async function main() {
  const Asset1155 = await ethers.getContractFactory("Asset1155");

  const asset1155 = await Asset1155.deploy("https");

  await asset1155.deployed();

  console.log("asset1155 deployed to:", asset1155.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
