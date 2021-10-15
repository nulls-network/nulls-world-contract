const hre = require("hardhat")
const fs = require("fs");

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/bigPrizePool/getRewardStartDayIndex.js --network ht-testnet

const contractName = "NullsBigPrizePool";
let contractAddr = "";

async function main() {
  await readConfig();
  contract = await connectContract(contractName, contractAddr)
  
  const [owner] = await hre.ethers.getSigners();

  ret = await contract.RewardStartDayIndex(owner.address);
  console.log("reward start:", ret.toNumber());

  ret = await contract.DayIndex();
  console.log("dayIndex:", ret.toNumber());

}

async function readConfig() {
  const configFile = "./scripts/config.json"
  let rawdata = fs.readFileSync(configFile)
  rwaJsonData = JSON.parse(rawdata)
  contractAddr = rwaJsonData['contrat_address']['NullsBigPrizePool'];
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
