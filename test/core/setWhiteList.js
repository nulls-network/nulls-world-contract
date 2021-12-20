const hre = require("hardhat")
const fs = require("fs");

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/core/setWhiteList.js --network ht-testnet

const coreContractName = "NullsWorldCore";
let coreContractAddr = "";
const whiteAddr = "0x7eaC202adA748510e7C54271F1fE61cF4aC574E7";

async function main () {
  await readConfig()
  coreContract = await connectContract(coreContractName, coreContractAddr)

  res = await coreContract.addNewItemWhiteList(whiteAddr)
  await res.wait()
}

async function readConfig () {
  const configFile = "./scripts/config.json"
  let rawdata = fs.readFileSync(configFile)
  rwaJsonData = JSON.parse(rawdata)
  coreContractAddr = rwaJsonData['contrat_address']['NullsWorldCore'];
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
