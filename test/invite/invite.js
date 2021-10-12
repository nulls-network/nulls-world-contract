const hre = require("hardhat")
const fs = require("fs");

// 邀请测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/invite/invite.js --network ht-testnet-user1

const contractName = "NullsInvite";
let contractAddr = "";
const superior = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";

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
