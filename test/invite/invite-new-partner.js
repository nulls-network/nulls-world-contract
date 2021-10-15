const hre = require("hardhat")
const fs = require("fs")

// 设置合伙人测试脚本，使用ht-testnet测试
// npx hardhat run test/invite/invite-new-partner.js --network ht-testnet

const contractName = "NullsInvite";
let contractAddr = "";
const partner = "0x84EAFa138bEcA0D8AEE173D7Bc2Df8B240B0d89e";

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
