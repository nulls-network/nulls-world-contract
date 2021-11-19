const hre = require("hardhat")
const fs = require("fs");

// 邀请测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/invite/invite.js --network ht-testnet-user3

const contractName = "NullsInvite";
let contractAddr = "";
const superior = "0x8c47494c675333dc613547600432d53ae78b272f";

async function main() {

  await readConfig()
  contract = await connectContract(contractName, contractAddr)
  await contract.invite(superior)
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
