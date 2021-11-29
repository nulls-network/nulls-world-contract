const hre = require("hardhat")
const fs = require("fs");

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/lpStaking/stake.js --network ht-testnet-user1

const contractName = "LPStaking";
let contractAddr = "";

const stakingTokenName = "NullsERC20Token";
let stakingTokenAddress = "";

const stakeAmount = 100000000;

async function main () {
  await readConfig();
  contract = await connectContract(contractName, contractAddr)

  stakingTokenContract = await connectContract(stakingTokenName, stakingTokenAddress)
  ret = await stakingTokenContract.approve(contract.address, stakeAmount)
  await ret.wait();

  ret = await contract.stake(stakeAmount)
  await ret.wait()
}

async function readConfig () {
  const configFile = "./scripts/config.json"
  let rawdata = fs.readFileSync(configFile)
  rwaJsonData = JSON.parse(rawdata)
  contractAddr = rwaJsonData['contrat_address'][contractName];
  stakingTokenAddress = rwaJsonData['contrat_address']["NullsErc20TestToken"];
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
