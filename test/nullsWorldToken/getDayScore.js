const hre = require("hardhat")
const fs = require("fs");

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/nullsWorldToken/getDayScore.js --network ht-testnet-user1

const contractName = "NullsWorldToken";
let contractAddr = "";


async function main () {
  await readConfig();
  contract = await connectContract(contractName, contractAddr)
  const [owner] = await hre.ethers.getSigners();
  console.log(owner.address)
  ret = await contract.getDayScore(owner.address, 0)
  console.log(ret)
}

async function readConfig () {
  const configFile = "./scripts/config.json"
  let rawdata = fs.readFileSync(configFile)
  rwaJsonData = JSON.parse(rawdata)
  contractAddr = rwaJsonData['contrat_address']['NullsMainToken'];
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
