const hre = require("hardhat")

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/rank/pk.js --network ht-testnet-user1

const contractName = "NullsRankManager";
const contractAddr = "0xeE156C0d169eb3B6b3Cde3BBF306c87e3afe65be";

const transferProxy = "0x3Cc1Ad4766c8b4D8a21B233Bae4Ef55c30139Ebd";

const eggTokenAddr = "0x4D27BABe8dD0D6737675A327D22C97f7B5a24c38";
const eggTokenContractName = "NullsEggToken";
const pkFee = 100;
async function main() {

  rankContract = await connectContract(contractName, contractAddr)
  while(true) {
    // 授权
    tokenContract = await connectContract(eggTokenContractName, eggTokenAddr)
    ret = await tokenContract.approve(transferProxy, pkFee)
    await ret.wait()
    
    let time = Math.floor((new Date().getTime() + 3600*1000)/1000)
    ret = await rankContract.pk(1, 250, time)
    console.log(ret)
    await ret.wait()
  }
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
