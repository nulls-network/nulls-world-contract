const hre = require("hardhat")
const fs = require("fs");

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/egg/refund.js --network ht-testnet-user1

const contractName = "NullsEggManager";
let contractAddr = "";
const requestKey = "0x606b42a0dfad70256c06d1b38fce1f41f17b7cd86d8996bcb7479e9951855392";

async function main () {
  await readConfig();
  contract = await connectContract(contractName, contractAddr)

  ret = await contract.refund(requestKey)
  console.log(await ret.wait())

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
