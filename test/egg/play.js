const fs = require("fs");
const hre = require("hardhat")

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/egg/play.js --network ht-testnet


let coreContractAddr = "";
const coreContractName = "NullsWorldCore";

async function main() {

  await readConfig()
  coreContract = await connectContract(coreContractName, coreContractAddr)

  await coreContract.play(
    "0xc8dc2fe784aed59c9f7f365516b5e9cb0beb4b38111b23b2f8028e127c14c5be",
    1633688989,
    27,
    "0x58165c6e0f80d7f6d1d8b3f6eecc8c447c0e60c7fffb17658b7a30740e70d134",
    "0x601625dd43313bcbef14495391a1739852e17c87bbab9717ce2e31637dbb9937"
  )

}

async function readConfig() {
  const configFile = "./scripts/config.json"
  let rawdata = fs.readFileSync(configFile)
  rwaJsonData = JSON.parse(rawdata)
  coreContractAddr = rwaJsonData['contrat_address']['worldCore_address'];
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
