const hre = require("hardhat")
// const eth = require("ethers");
// const { ethers } = require("hardhat");
// const httpUtils = require("./httpUtils");
const fs = require("fs");

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/rank/newRank.js --network ht-testnet-user1

const contractName = "NullsRankManager";
let contractAddr = "";


const nullsErc20TokenContractName = "NullsERC20Token";
let nullsERC20Token = "";
let transferProxy = "";
let rewardRatio = 60;
async function createRing () {
  await readConfig()
  let tokenContract = await connectContract(nullsErc20TokenContractName, nullsERC20Token);
  ret = await tokenContract.approve(transferProxy, 1000 * 10000000);
  await ret.wait();

  //创建擂台 
  let ringManager_contrcat = await connectContract(contractName, contractAddr);

  let petId = 7;
  let multiple = 5;

  await ringManager_contrcat.createRank(petId, nullsERC20Token, multiple, rewardRatio);
}

async function readConfig () {
  const configFile = "./scripts/config.json"
  let rawdata = fs.readFileSync(configFile)
  rwaJsonData = JSON.parse(rawdata)
  contractAddr = rwaJsonData['contrat_address']['NullsRankManager'];
  nullsERC20Token = rwaJsonData['contrat_address']['NullsErc20TestToken'];
  transferProxy = rwaJsonData['contrat_address']['TransferProxy'];
}

async function connectContract (contractName, contractAddress) {
  const [owner] = await hre.ethers.getSigners();
  let contract = await hre.ethers.getContractAt(contractName, contractAddress, owner)

  console.log(`connected ${contractName} address is : ${contract.address}`)
  return contract;
}

async function main () {
  await createRing();
}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });