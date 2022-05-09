import { FarmingPool } from "./../typechain-types/FarmingPool";
import { ethers } from "hardhat";

async function main() {
  const FarmingPool = await ethers.getContractFactory("FarmingPool");

  const farmingPool = (await FarmingPool.attach(
    "0xd367118bA9BbFcFF3f0688b0A314017246C92297"
  )) as FarmingPool;

  await farmingPool.transferAKC(
    ethers.utils.parseEther("7795"),
    "0x6596639cEbd0409dD308Ea3b90808F6B44698948"
  );

  console.log("interact successfully");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
