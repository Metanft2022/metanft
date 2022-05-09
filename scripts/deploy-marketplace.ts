/* eslint-disable no-process-exit */
// @ts-ignore
import { ethers, upgrades } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const ContractFactory = await ethers.getContractFactory("Marketplace");
  const Contract = await ContractFactory.deploy(
    "0x00630E7e512d9159758d93F5AcDeF321FCA21F09",
    450
  );

  const farmingPool = await Contract.deployed();

  console.log("Marketplace address:", farmingPool.address);
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
