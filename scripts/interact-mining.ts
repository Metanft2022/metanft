import { FarmingPool } from "./../typechain-types/FarmingPool";
import { ethers } from "hardhat";

async function main() {
  const FarmingPool = await ethers.getContractFactory("FarmingPool");

  const farmingPool = (await FarmingPool.attach(
    "0xaEb5CD47b35C1C7013b2f7F20934e72B7047eE7C"
  )) as FarmingPool;

  await farmingPool.setFarmingBUSDPool("1", "0", "100");

  console.log("interact successfully");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
