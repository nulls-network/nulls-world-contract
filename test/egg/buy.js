const hre = require("hardhat")

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/egg/buy.js --network ht-testnet-user1

const contractName = "NullsEggManager";
const contractAddr = "0x0E8ad150562532370671E948EfFFfF4E0aec1027";

const buyEggTokenContractName = "NullsERC20Token";
const buyEggTokenAddr = "0x6aA7CF4F83c6a88cABD93b40D47E7144311882B8";
const transferProxy = "0x2E3C21C1B7D8E9f19EFF4f000EbdAEACD9DfDD64";

// 买蛋数量
const buyCount = 10; 
const price = 100 * 1000000;

async function main() {

  contract = await connectContract(contractName, contractAddr)
  
  // 授权
  tokenContract = await connectContract(buyEggTokenContractName, buyEggTokenAddr)
  ret = await tokenContract.approve(transferProxy, buyCount * price)
  await ret.wait();

  // 购买
  ret = await contract.buy(buyCount, buyEggTokenAddr)
  await ret.wait()
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
