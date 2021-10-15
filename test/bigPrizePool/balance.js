const hre = require("hardhat")
const fs = require("fs");

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/bigPrizePool/balance.js --network ht-testnet-user1

const contractName = "NullsBigPrizePool";
let contractAddr = "";

async function main() {
  await readConfig();
  contract = await connectContract(contractName, contractAddr)
  
  ret = await contract.updateStatistics();
  await ret.wait()
  ret = await contract.Balance();
  console.log("balance:", ret.toNumber());
  ret = await contract.PoolTokenAmount();
  console.log("pool size:", ret.toNumber());
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
