import { VirtualPropertyRight } from "./../typechain-types/VirtualPropertyRight";
import { ethers } from "hardhat";

async function main() {
  const VirtualPropertyRight = await ethers.getContractFactory(
    "VirtualPropertyRight"
  );

  const vpr = (await VirtualPropertyRight.attach(
    "0x25fE7AE8e98049b355aa449F17a30A3231aAeE43"
  )) as VirtualPropertyRight;

  await vpr.mint(
    "0x0037e6f09bfA826a5373CB030E379550A5CCDB7E",
    ethers.utils.parseEther("100000000")
  );

  console.log("interact successfully");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
