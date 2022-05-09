/* eslint-disable no-process-exit */
// @ts-ignore
import { ethers, upgrades } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const ContractFactory = await ethers.getContractFactory("FarmingPool");
  const Contract = await upgrades.deployProxy(
    ContractFactory,
    [
      "0x25fE7AE8e98049b355aa449F17a30A3231aAeE43",
      "0x0fa73D350E5e5bf63863f49Bb4bA3e87A20c93Fb",
      "0x00630E7e512d9159758d93F5AcDeF321FCA21F09",
      "0x00630E7e512d9159758d93F5AcDeF321FCA21F09",
      "0x32febf606277b859513253CC1Be93ed7F1f07682",
      "0xD11b908741198e85c315785e5846E7932F3F280a",
      "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56",
    ],
    { initializer: "__FarmingInit" }
  );

  const farmingPool = await Contract.deployed();

  console.log("Farming address:", farmingPool.address);
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
