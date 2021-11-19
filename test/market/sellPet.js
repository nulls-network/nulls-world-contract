const hre = require("hardhat")
const fs = require("fs");

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/market/sellPet.js --network ht-testnet-user1

const contractName = "NullsPetToken";
let contractAddr = "";

let transferProxy = "";

let c20TokenAddr = "";
const sellFee = 100;
const petId = 1;
async function main () {

  await readConfig()
  rankContract = await connectContract(contractName, contractAddr)

  // ret = await rankContract.setSupportedToken(c20TokenAddr, true, 30);
  // await ret.wait()
  // 授权
  ret = await rankContract.approve(transferProxy, petId)
  await ret.wait()

  ret = await rankContract.sellPet(petId, c20TokenAddr, sellFee)
  await ret.wait()
}

async function readConfig () {
  const configFile = "./scripts/config.json"
  let rawdata = fs.readFileSync(configFile)
  rwaJsonData = JSON.parse(rawdata)
  contractAddr = rwaJsonData['contrat_address']['NullsPetToken'];
  transferProxy = rwaJsonData['contrat_address']['TransferProxy'];
  c20TokenAddr = rwaJsonData['contrat_address']['NullsErc20TestToken'];
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
