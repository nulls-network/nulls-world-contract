const fs = require("fs");
const hre = require("hardhat")

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/rank/refund.js --network ht-testnet-user1

const contractName = "NullsRankManager"
let contractAddr = ""

const requestKey = "0x8dde37c4d8abdbde9402dbfd7c2726c323ab2cb10734424af7dc0e26d832ee71"

async function main () {

  await readConfig()
  rankContract = await connectContract(contractName, contractAddr)
  ret = await rankContract.refund(requestKey)
  await ret.wait()
}

async function readConfig () {
  const configFile = "./scripts/config.json"
  let rawdata = fs.readFileSync(configFile)
  rwaJsonData = JSON.parse(rawdata)
  contractAddr = rwaJsonData['contrat_address']['NullsRankManager'];
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
