import { ethers, upgrades } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const ContractFactory = await ethers.getContractFactory("ICO");
  const Contract = await upgrades.deployProxy(
    ContractFactory,
    [
      ethers.utils.parseEther("5000000000"),
      "0x25fE7AE8e98049b355aa449F17a30A3231aAeE43",
      "20000000000000000",
      "0xf85360211e7Bd645bBe93b078F96765F0D339A02",
      "0xdA92F647927830F0Db7afefE24D9e87852626625",
      "0xb7c290e9bbf8d1d0EAE94D4DaAd62163c48EFF2b",
      "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56 ",
    ],
    { initializer: "__ICOInit" }
  );

  const farmingPool = await Contract.deployed();

  console.log("ICO address:", farmingPool.address);
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
