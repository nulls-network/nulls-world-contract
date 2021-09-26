const hre = require("hardhat")

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/market/sellPet.js --network ht-testnet-user1

const contractName = "NullsPetToken";
const contractAddr = "0x416914b24eDb3A4dd6Ab62d034fd7827fB233024";

const transferProxy = "0x3Cc1Ad4766c8b4D8a21B233Bae4Ef55c30139Ebd";

const c20TokenAddr = "0x6aA7CF4F83c6a88cABD93b40D47E7144311882B8";
const c20TokenContractName = "NullsERC20Token";
const sellFee = 100;
const petId = 200;
async function main() {

  rankContract = await connectContract(contractName, contractAddr)
  
  // ret = await rankContract.setSupportedToken(c20TokenAddr, true, 30);
  // await ret.wait()
  // 授权
  ret = await rankContract.approve(transferProxy, petId)
  await ret.wait()
  
  ret = await rankContract.sellPet(petId, c20TokenAddr, sellFee)
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
