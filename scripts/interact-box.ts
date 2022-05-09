import { Akashic } from "../typechain-types/Akashic";
import { ethers } from "hardhat";

async function main() {
  const Box = await ethers.getContractFactory("Box");

  const box = (await Box.attach(
    "0xAA9E659a2800Fb24C036b7924A9FF86aF57cc5A7"
  )) as Akashic;

  console.log("interact successfully");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
