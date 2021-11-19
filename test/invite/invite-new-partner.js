const hre = require("hardhat")
const fs = require("fs")

// 设置合伙人测试脚本，使用ht-testnet测试
// npx hardhat run test/invite/invite-new-partner.js --network ht-testnet

const contractName = "NullsInvite";
let contractAddr = "";
const partner = "0x9e68cd522683754A9945E243A045976199e20c4d";

async function main() {

  await readConfig()
  contract = await connectContract(contractName, contractAddr)
  await contract.addPartner(partner)
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
