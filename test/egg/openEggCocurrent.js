const hre = require("hardhat")
const fs = require("fs");

const {NonceManager} = require("@ethersproject/experimental");

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/egg/openEggCocurrent.js --network ht-testnet-user1

const contractName = "NullsEggManager";
let contractAddr = "";

let transferProxy = "";

let eggTokenAddr = "";
const eggTokenContractName = "NullsEggToken";
const openEggNumber = 20;
const concurrentNumber = 10;
async function main() {

  await readConfig()
  eggContract = await connectContract(contractName, contractAddr)
  
  // 授权
  tokenContract = await connectContract(eggTokenContractName, eggTokenAddr)
  ret = await tokenContract.approve(transferProxy, openEggNumber * concurrentNumber)
  await ret.wait()
  
  let array = [];
  for (let i = 0; i < concurrentNumber; i++) {
    let time = Math.floor((new Date().getTime() + 3600*1000)/1000)
    array[i] = await eggContract.openMultiple(openEggNumber, 0, time)
    console.log("-------", i)
  }

  for (let i = 0; i < array.length; i++) {
    try {
      ret = await array[i].wait()
    } catch (e) {
      console.warn(e)
    }
    
    console.log(ret)
  }
}

async function readConfig() {
  const configFile = "./scripts/config.json"
  let rawdata = fs.readFileSync(configFile)
  rwaJsonData = JSON.parse(rawdata)
  contractAddr = rwaJsonData['contrat_address']['EggManager_address'];
  transferProxy = rwaJsonData['contrat_address']['TransferProxy'];
  eggTokenAddr = rwaJsonData['contrat_address']['EggToken_address'];
}

async function connectContract(contractName, contractAddress) {
  const [owner] = await hre.ethers.getSigners();
  const managedSigner = new NonceManager(owner);
  let contract = await hre.ethers.getContractAt( contractName ,contractAddress, managedSigner)

  console.log(`connected ${contractName} address is : ${contract.address}`)
  return contract;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
