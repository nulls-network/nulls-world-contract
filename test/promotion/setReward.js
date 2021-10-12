const hre = require("hardhat")
const fs = require("fs");

// 奖励领取测试脚本
// npx hardhat run test/promotion/setReward.js --network ht-testnet

const contractName = "NullsPromotion";
let contractAddr = "";
// 预售活动奖励的 token 总数
const promotionTotal = 210000 * 1000000
// 预售活动开始时间(UTC时间)
const promotionStartTime = new Date(Date.UTC(2021, 10 - 1, 1, 0, 0, 0)).getTime() / 1000
// const promotionStartTime = new Date(Date.UTC(year, month - 1, day, hour, minute, second))
// 预售活动结束时间
const promotionEndTime = new Date(Date.UTC(2021, 10 - 1, 30, 0, 0, 0)).getTime() / 1000

let rewardTokenAddr = "";

async function main() {

  await readConfig()
  contract = await connectContract(contractName, contractAddr)
  
  ret = await contract.setReward(rewardTokenAddr,promotionTotal, promotionStartTime, promotionEndTime)

  await ret.wait()

}

async function connectContract(contractName, contractAddress) {
  const [owner] = await hre.ethers.getSigners();
  let contract = await hre.ethers.getContractAt( contractName ,contractAddress, owner)

  console.log(`connected ${contractName} address is : ${contract.address}`)
  return contract;
}

async function readConfig() {
  const configFile = "./scripts/config.json"
  let rawdata = fs.readFileSync(configFile)
  rwaJsonData = JSON.parse(rawdata)
  contractAddr = rwaJsonData['contrat_address']['NullsPromotion'];
  rewardTokenAddr = rwaJsonData['contrat_address']['NullsMainToken'];
}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
