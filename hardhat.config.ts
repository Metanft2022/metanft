import * as dotenv from "dotenv";

import { HardhatUserConfig, task } from "hardhat/config";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import "@typechain/hardhat";
import "@openzeppelin/hardhat-upgrades";

dotenv.config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
// task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
//   const accounts = await hre.ethers.getSigners();

//   for (const account of accounts) {
//     console.log(account.address);
//   }
// });

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config = {
  solidity: "0.8.8",
  networks: {
    ropsten: {
      url: process.env.ROPSTEN_URL || "",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    bsc_testnet: {
      url: `https://data-seed-prebsc-2-s3.binance.org:8545/`,
      chainId: 97,
      gasPrice: 50000000000,
      accounts:
        process.env.DEPLOY_ACCOUNT_PRIVATE_KEY !== undefined
          ? [process.env.DEPLOY_ACCOUNT_PRIVATE_KEY]
          : [],
    },
    bsc: {
      url: `https://bsc-dataseed.binance.org/`,
      chainId: 56,
      gasPrice: 20000000000,
      accounts:
        process.env.DEPLOY_ACCOUNT_PRIVATE_KEY !== undefined
          ? [process.env.DEPLOY_ACCOUNT_PRIVATE_KEY]
          : [],
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};

export default config;
