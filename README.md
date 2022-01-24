
# Simple token smart contracts

## INTRO
This project is all the contracts of the simple token system, include:
* BEP20 / ERC20 Token (without test script)
* IDO contract (sell token in multi-round)
* Staking contract (stake token to get reward)
* Token - Token pair (also the swapping contract, liquidity token contract)
* Token - BNB pair (also the swapping contract, liquidity token contract)
* Data collector contract (gathering information from multi-contract)

## INSTALLATION
Environment requires:
* NodeJS 14+

Step by step:
* Clone the project: `git clone https://...`
* Install independent packages: `npm install`
* Run test script `npx hardhat test`

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
npx hardhat help
REPORT_GAS=true npx hardhat test
npx hardhat coverage
npx hardhat run scripts/deploy.js
node scripts/deploy.js
npx eslint '**/*.js'
npx eslint '**/*.js' --fix
npx prettier '**/*.{json,sol,md}' --check
npx prettier '**/*.{json,sol,md}' --write
npx solhint 'contracts/**/*.sol'
npx solhint 'contracts/**/*.sol' --fix
```

## DEPLOYMENT STEPS
Following these steps:
* Deploy ERC20 / BEP20 token contract
* Deploy IDO contract with input parameters are:
	* ERC20/BEP20 contract address
	* BUSD token address
	* Reward address (ERC20/BEP20 token)
* Staking contract with input parameters are:
	* ERC20/BEP20 contract address (also the staking and rewarding token)
* Token - Token pair contract with input parameters are:
	* ERC20/BEP20 contract address
	* BUSD token address
* Token - BNB pair contract with input parameters are:
	* ERC20/BEP20 contract address
* Data collector contract with input parameters are:
	* ERC20/BEP20 contract address
	* BUSD token address
	* Token - Token pair contract address
	* Token - BNB pair contract address

## ETHERSCAN VERIFICATION

To try out Etherscan verification, you first need to deploy a contract to an Ethereum network that's supported by Etherscan, such as Ropsten.

In this project, copy the .env.example file to a file named .env, and then edit it to fill in the details. Enter your Etherscan API key, your Ropsten node URL (eg from Alchemy), and the private key of the account which will send the deployment transaction. With a valid .env file in place, first deploy your contract:

```shell
hardhat run --network ropsten scripts/deploy.js
```

Then, copy the deployment address and paste it in to replace `DEPLOYED_CONTRACT_ADDRESS` in this command:

```shell
npx hardhat verify --network ropsten DEPLOYED_CONTRACT_ADDRESS "Hello, Hardhat!"
```
