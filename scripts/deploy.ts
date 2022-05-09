import { ethers } from "hardhat";

async function main() {
  const Box = await ethers.getContractFactory("Box");

  const box = await Box.deploy(
    "0x32febf606277b859513253CC1Be93ed7F1f07682",
    "0x25fE7AE8e98049b355aa449F17a30A3231aAeE43",
    "0x00630E7e512d9159758d93F5AcDeF321FCA21F09",
    ethers.utils.parseEther("125000")
  );

  await box.deployed();

  console.log("box deployed to:", box.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
