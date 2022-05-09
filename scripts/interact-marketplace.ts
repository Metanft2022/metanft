import { Marketplace } from "./../typechain-types/Marketplace";
import dayjs from "dayjs";
// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const Marketplace = await ethers.getContractFactory("Marketplace");
  //   const currentTime = dayjs();
  //   const lastTime = currentTime.add(10, "day");

  const marketplace = (await Marketplace.attach(
    "0x3E98a474b995bac987c18226A3aF4B5053FA27b9"
  )) as Marketplace;

  const myItems = await marketplace.getMyItemsOnSale();

  console.log(myItems, "interact successfully");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
