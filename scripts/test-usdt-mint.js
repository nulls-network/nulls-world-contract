const hre = require("hardhat")
const { exit } = require("process");

async function main () {

  // 用于测试期间支付购买宠物、pk的token
  contract = await connectContract("NullsERC20Token", "0x7383e90E2fd05f4E0CF0b8e389D3463d49d1630D")
  await contract.mint("0x6985E42F0cbF13a48b9DF9Ec845b652318793642", 10000000000000)
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
