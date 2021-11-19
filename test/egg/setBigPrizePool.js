const hre = require("hardhat")
const fs = require("fs");

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/egg/setBigPrizePool.js --network ht-testnet

const contractName = "NullsEggManager";
let contractAddr = "";

const bigPrizePoolContractName = "NullsBigPrizePool";
let bigPrizePoolAddr = "";


async function main () {
  await readConfig();
  contract = await connectContract(contractName, contractAddr)

  ret = await contract.setBigPrizePool(bigPrizePoolAddr)
  console.log(await ret.wait())

}

async function readConfig () {
  const configFile = "./scripts/config.json"
  let rawdata = fs.readFileSync(configFile)
  rwaJsonData = JSON.parse(rawdata)
  contractAddr = rwaJsonData['contrat_address']['NullsEggManager'];
  bigPrizePoolAddr = rwaJsonData['contrat_address']['NullsBigPrizePool'];
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
