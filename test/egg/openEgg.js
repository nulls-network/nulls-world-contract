const hre = require("hardhat")
const fs = require("fs");

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/egg/openEgg.js --network ht-testnet-user1

const contractName = "NullsEggManager";
let contractAddr = "";

let transferProxy = "";

let eggTokenAddr = "";
const eggTokenContractName = "NullsEggToken";
const openEggNumber = 20;
async function main () {

  await readConfig()
  eggContract = await connectContract(contractName, contractAddr)

  // 授权
  tokenContract = await connectContract(eggTokenContractName, eggTokenAddr)
  ret = await tokenContract.approve(transferProxy, openEggNumber)
  await ret.wait()

  let time = Math.floor((new Date().getTime() + 3600 * 1000) / 1000)
  ret = await eggContract.openMultiple(openEggNumber, 29, time)
  await ret.wait()

}

async function readConfig () {
  const configFile = "./scripts/config.json"
  let rawdata = fs.readFileSync(configFile)
  rwaJsonData = JSON.parse(rawdata)
  contractAddr = rwaJsonData['contrat_address']['NullsEggManager'];
  transferProxy = rwaJsonData['contrat_address']['TransferProxy'];
  eggTokenAddr = rwaJsonData['contrat_address']['NullsEggToken'];
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
