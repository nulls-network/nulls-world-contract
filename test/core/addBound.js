const hre = require("hardhat")
const fs = require("fs");

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/core/addBound.js --network ht-testnet

let coreContractAddr = "";
const coreContractName = "NullsWorldCore";

async function main() {
  await readConfig()
  coreContract = await connectContract(coreContractName, coreContractAddr)

  res = await coreContract.addBound(1)
  await res.wait()
}

async function readConfig() {
  const configFile = "./scripts/config.json"
  let rawdata = fs.readFileSync(configFile)
  rwaJsonData = JSON.parse(rawdata)
  coreContractAddr = rwaJsonData['contrat_address']['worldCore_address'];
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
