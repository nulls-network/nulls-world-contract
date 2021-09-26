const hre = require("hardhat")

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/market/unSellPet.js --network ht-testnet-user1

const contractName = "NullsPetToken";
const contractAddr = "0x416914b24eDb3A4dd6Ab62d034fd7827fB233024";

const petId = 200;
async function main() {

  rankContract = await connectContract(contractName, contractAddr)
  
  ret = await rankContract.unSellPet(petId)
  await ret.wait()
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
