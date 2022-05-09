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
  const Airdrop = await ethers.getContractFactory("Airdrop");

  const airdrop = await Airdrop.deploy(
    "0xD85e13a9e20d82D13BA248a3e5Bc1A51f43f7f93",
    "0x5f717E897DdF2A1d2F6B60214d0263c159fb6486",
    "0xdA92F647927830F0Db7afefE24D9e87852626625",
    "0x25fE7AE8e98049b355aa449F17a30A3231aAeE43",
    "0xD11b908741198e85c315785e5846E7932F3F280a"
  );

  await airdrop.deployed();

  console.log("airdrop deployed to:", airdrop.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
