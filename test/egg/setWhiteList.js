const hre = require("hardhat")
const fs = require("fs");

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/egg/setWhiteList.js --network ht-testnet

const contractName = "NullsEggManager";
let contractAddr = "";
const whiteAddr = "0x7eaC202adA748510e7C54271F1fE61cF4aC574E7";

async function main () {
  await readConfig();
  contract = await connectContract(contractName, contractAddr)

  ret = await contract.addWhiteList(whiteAddr)
  await ret.wait()

}

async function readConfig () {
  const configFile = "./scripts/config.json"
  let rawdata = fs.readFileSync(configFile)
  rwaJsonData = JSON.parse(rawdata)
  contractAddr = rwaJsonData['contrat_address']['NullsEggManager'];
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
