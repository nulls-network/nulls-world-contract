const hre = require("hardhat")
const fs = require("fs");

// 邀请测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/invite/statistics.js --network ht-testnet-user1

const contractName = "NullsInvite";
let contractAddr = "";
const user = "0xB1877E668f3827FF8301EfEAe6aB7aB081d75f11";

async function main() {

  await readConfig()
  contract = await connectContract(contractName, contractAddr)
  ret = await contract.getInviteStatistics(user)
  console.log(ret)
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
  contractAddr = rwaJsonData['contrat_address']['NullsInvite'];
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
