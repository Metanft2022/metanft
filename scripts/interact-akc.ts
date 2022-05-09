import { Akashic } from "../typechain-types/Akashic";
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
  const Akashic = await ethers.getContractFactory("Akashic");

  const aks = (await Akashic.attach(
    "0x3DC7A4858d249595B6aE47D0C08fb21216c4BE89"
  )) as Akashic;

  await aks.approve(
    "0xaEb5CD47b35C1C7013b2f7F20934e72B7047eE7C",
    ethers.utils.parseEther("100000000")
  );

  console.log("interact successfully");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
