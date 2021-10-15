const hre = require("hardhat")
const fs = require("fs");

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/bigPrizePool/receiveDayReward.js --network ht-testnet

const contractName = "NullsBigPrizePool";
let contractAddr = "";
const dayIndex = 648;

async function main() {
  await readConfig();
  contract = await connectContract(contractName, contractAddr)
  const [owner] = await hre.ethers.getSigners();

  ret = await contract.getUserDayTransferPercent(owner.address, dayIndex)
  console.log("day percent = ", ret)
  await contract.transferOut(dayIndex)
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
