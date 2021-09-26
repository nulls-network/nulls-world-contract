const hre = require("hardhat")

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/egg/newEggItem.js --network ht-testnet

const contractName = "NullsEggManager";
const contractAddr = "0xF645Ac66E9cCf4D3c38B79a7Ad240fBb158a7058";

const coreContractAddr = "0xb6233730B7Dc3f83e58FA2Cd9Ca973179EDB0C22";
const coreContractName = "NullsWorldCore";

async function main() {

  eggContract = await connectContract(contractName, contractAddr)
  coreContract = await connectContract(coreContractName, coreContractAddr)

  sceneId = await eggContract.getSceneId()
  console.log("sceneId = ", sceneId)

  await coreContract.newItem(sceneId, "0xeDdc51b795220FAB767Ee17c779345AE2177C4EA")

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
