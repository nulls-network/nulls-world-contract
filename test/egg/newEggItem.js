const hre = require("hardhat")
const fs = require("fs");

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/egg/newEggItem.js --network ht-testnet

const contractName = "NullsEggManager";
let contractAddr = "";

let coreContractAddr = "";
const coreContractName = "NullsWorldCore";

async function main () {
  await readConfig()
  eggContract = await connectContract(contractName, contractAddr)
  coreContract = await connectContract(coreContractName, coreContractAddr)

  sceneId = await eggContract.getSceneId()
  console.log("sceneId = ", sceneId)

  res = await coreContract.newItem(sceneId, "0xeDdc51b795220FAB767Ee17c779345AE2177C4EA", 0)
  // await res.wait()
  // 用上面的ItemId来异步设置公钥
  // res = await coreContract.addPubkeyAsync(0, "0xeDdc51b795220FAB767Ee17c779345AE2177C4EA")
  await res.wait()
}

async function readConfig () {
  const configFile = "./scripts/config.json"
  let rawdata = fs.readFileSync(configFile)
  rwaJsonData = JSON.parse(rawdata)
  contractAddr = rwaJsonData['contrat_address']['NullsEggManager'];
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
