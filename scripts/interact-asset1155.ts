import { Asset1155 } from "./../typechain-types/Asset1155";
import { ethers } from "hardhat";

async function main() {
  const Asset1155 = await ethers.getContractFactory("Asset1155");

  const asset1155 = (await Asset1155.attach(
    "0x025Ff4e6BdBBcE8d2214DEBff130eC0C7ea825B0"
  )) as Asset1155;

  await asset1155.balanceOf("0x0037e6f09bfA826a5373CB030E379550A5CCDB7E", "1");

  console.log("successfully");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
