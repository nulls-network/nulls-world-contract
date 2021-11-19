const fs = require("fs");
const hre = require("hardhat")

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/rank/pk.js --network ht-testnet-user1

const contractName = "NullsRankManager";
let contractAddr = "";

let transferProxy = "";

let nullsERC20Token = "";
const nullsErc20TokenContractName = "NullsERC20Token";
const pkFee = 100 * 1000000;
async function main () {

  await readConfig()
  rankContract = await connectContract(contractName, contractAddr)
  // ret = await rankContract.setRestTime(1);
  // await ret.wait()

  tokenContract = await connectContract(nullsErc20TokenContractName, nullsERC20Token)
  ret = await tokenContract.approve(transferProxy, 40 * pkFee)
  await ret.wait()

  ret1 = batchPk1(rankContract, 34)
  ret2 = batchPk2(rankContract, 35)

  await ret1;
  await ret2;
}

async function batchPk1(rankContract, itemId) {
  for (let i = 14; i < 22; i++) {
    try {
      let time = Math.floor((new Date().getTime() + 3600 * 1000) / 1000)
      ret = await rankContract.pk(itemId, i, time)
      // await ret.wait()
      console.log("count:", i)
    } catch (error) {
      console.log(error)
    }
  }
}

async function batchPk2(rankContract, itemId) {
  for (let i = 70; i < 78; i++) {
    try {
      let time = Math.floor((new Date().getTime() + 3600 * 1000) / 1000)
      ret = await rankContract.pk(itemId, i, time)
      // await ret.wait()
      console.log("count:", i)
    } catch (error) {
      console.log(error)
    }
  }
}

async function readConfig () {
  const configFile = "./scripts/config.json"
  let rawdata = fs.readFileSync(configFile)
  rwaJsonData = JSON.parse(rawdata)
  contractAddr = rwaJsonData['contrat_address']['NullsRankManager'];
  nullsERC20Token = rwaJsonData['contrat_address']['NullsErc20TestToken'];
  transferProxy = rwaJsonData['contrat_address']['TransferProxy'];
}

async function connectContract (contractName, contractAddress) {
  const [owner] = await hre.ethers.getSigners();
  let contract = await hre.ethers.getContractAt(contractName, contractAddress, owner)

  console.log(`connected ${contractName} address is : ${contract.address}`)
  return contract;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
