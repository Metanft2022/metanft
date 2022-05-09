import { Airdrop } from "./../typechain-types/Airdrop";
import axios from "axios";
import { ethers } from "hardhat";

async function main() {
  const Airdrop = await ethers.getContractFactory("Airdrop");

  const airdrop = (await Airdrop.attach(
    "0x06800feA5D7f1aF642cA4F01DAf0a998C6293872"
  )) as Airdrop;

  const payload = await axios.get(
    `https://backend.vprchain.io/api/airdrop/0xE9e79857fEc00a89a19C64A5E2DD500Aa2aD6f16`
  );

  const signature = payload.data.data.signature;

  await airdrop.claimAirDropWithSig(
    payload.data.data.amount,
    {
      deadline: signature.deadline,
      v: signature.v,
      r: signature.r.data,
      s: signature.s.data,
    },
    "0x0000000000000000000000000000000000000000"
  );

  console.log("interact successfully");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
