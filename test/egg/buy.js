const hre = require("hardhat")

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/egg/buy.js --network ht-testnet-user1

const contractName = "NullsEggManager";
const contractAddr = "0xF645Ac66E9cCf4D3c38B79a7Ad240fBb158a7058";

const buyEggTokenContractName = "NullsERC20Token";
const buyEggTokenAddr = "0x6aA7CF4F83c6a88cABD93b40D47E7144311882B8";
const transferProxy = "0x3Cc1Ad4766c8b4D8a21B233Bae4Ef55c30139Ebd";

// 买蛋数量
const buyCount = 1000; 
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
