import { ICO } from "./../typechain-types/ICO";
import dayjs from "dayjs";
import { ethers } from "hardhat";

async function main() {
  const ICO = await ethers.getContractFactory("ICO");
  const currentTime = dayjs();
  const lastTime = currentTime.add(10, "day");

  const ico = (await ICO.attach(
    "0xD11b908741198e85c315785e5846E7932F3F280a"
  )) as ICO;

  await ico.modifyIcoRound("1", "1000", "1000", lastTime.unix());

  console.log("interact successfully");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
