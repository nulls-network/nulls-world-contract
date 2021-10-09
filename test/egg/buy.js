const hre = require("hardhat")
const fs = require("fs");

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/egg/buy.js --network ht-testnet-user1

const contractName = "NullsEggManager";
let contractAddr = "";

const buyEggTokenContractName = "NullsERC20Token";
let buyEggTokenAddr = "";
let transferProxy = "";

// 买蛋数量
const buyCount = 1; 
const price = 100 * 1000000;

async function main() {
  await readConfig();
  contract = await connectContract(contractName, contractAddr)
  
  // 授权
  tokenContract = await connectContract(buyEggTokenContractName, buyEggTokenAddr)
  ret = await tokenContract.approve(transferProxy, buyCount * price * 60)
  await ret.wait();

  ret = await contract.buy(buyCount, buyEggTokenAddr)
  console.log(await ret.wait())
  
}

async function readConfig() {
  const configFile = "./scripts/config.json"
  let rawdata = fs.readFileSync(configFile)
  rwaJsonData = JSON.parse(rawdata)
  contractAddr = rwaJsonData['contrat_address']['EggManager_address'];
  buyEggTokenAddr = rwaJsonData['contrat_address']['NullsErc20TestToken'];
  transferProxy = rwaJsonData['contrat_address']['TransferProxy'];
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
