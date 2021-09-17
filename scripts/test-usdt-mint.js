const hre = require("hardhat")
const { exit } = require("process");

async function main() {

  // 用于测试期间支付购买宠物、pk的token
  contract = await connectContract("NullsERC20Token", "0x6aA7CF4F83c6a88cABD93b40D47E7144311882B8")
  await contract.mint("0x60DcDAAb41735e9A747a3D6a78DE563f3DF34b90", 10000000000000)
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