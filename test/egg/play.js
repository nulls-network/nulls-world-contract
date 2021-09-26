const hre = require("hardhat")

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/egg/buy.js --network ht-testnet


const coreContractAddr = "0xC5cd21aeFb28e2AA289e16da7e2E6e1399b2284d";
const coreContractName = "NullsWorldCore";

async function main() {

  
  coreContract = await connectContract(coreContractName, coreContractAddr)

  await coreContract.play(
    "0xccd88719cc377f0a5ec5f596857fbd01606069c741451127968612773c6e6016",
    1632468820,
    27,
    "0xad1a2cd8ccf44787264308d42d57489915ce0371dd0a12754f179a7573c500fe",
    "0x5b52915df54cfa1bd354bb1a6e0b3b15ffa8ac42a80e82d264e4307f0dfba9f5"
  )

}

async function connectContract(contractName, contractAddress) {
  const [owner] = await hre.ethers.getSigners();
  let contract = await hre.ethers.getContractAt( contractName ,contractAddress, owner)

  console.log(`connected ${contractName} address is : ${contract.address}`)
  return contract;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
