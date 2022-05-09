import { BUSD } from "./../typechain-types/BUSD";
import { ethers } from "hardhat";

async function main() {
  const BUSD = await ethers.getContractFactory("BUSD");

  const busd = (await BUSD.attach(
    "0xB21010B222970082b77b332A2CbE1bF32555f20f"
  )) as BUSD;

  await busd.mint(
    "0xbC3A0Bd6E77544f3B10940962F902Db76a646B04",
    ethers.utils.parseEther("100000000")
  );

  console.log("interact successfully");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
