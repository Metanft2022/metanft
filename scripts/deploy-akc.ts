import { ethers } from "hardhat";

async function main() {
  const Akashic = await ethers.getContractFactory("Akashic");

  const akashic = await Akashic.deploy();

  await akashic.deployed();

  console.log("AKC deployed to:", akashic.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
