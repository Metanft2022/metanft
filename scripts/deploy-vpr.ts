import { ethers } from "hardhat";

async function main() {
  const VirtualPropertyRight = await ethers.getContractFactory(
    "VirtualPropertyRight"
  );

  const virtualPropertyRight = await VirtualPropertyRight.deploy();

  await virtualPropertyRight.deployed();

  console.log("VPR deployed to:", virtualPropertyRight.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
