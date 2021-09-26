const hre = require("hardhat")

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/egg/openEgg.js --network ht-testnet-user1

const contractName = "NullsEggManager";
const contractAddr = "0xF645Ac66E9cCf4D3c38B79a7Ad240fBb158a7058";

const transferProxy = "0x3Cc1Ad4766c8b4D8a21B233Bae4Ef55c30139Ebd";

const eggTokenAddr = "0x4D27BABe8dD0D6737675A327D22C97f7B5a24c38";
const eggTokenContractName = "NullsEggToken";
const openEggNumber = 20;
async function main() {

  eggContract = await connectContract(contractName, contractAddr)
  
  // 授权
  tokenContract = await connectContract(eggTokenContractName, eggTokenAddr)
  ret = await tokenContract.approve(transferProxy, openEggNumber)
  await ret.wait()
  
  let time = Math.floor((new Date().getTime() + 3600*1000)/1000)
  ret = await eggContract.openMultiple(openEggNumber, 0, time)
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
