const hre = require("hardhat")

// 取消设置合伙人测试脚本，使用ht-testnet测试
// npx hardhat run test/invite/invite-del-partner.js --network ht-testnet

const contractName = "NullsInvite";
const contractAddr = "0x70a5F1D82d25C6Cb69ad73b30068C7c748553667";
const partner = "0xB1877E668f3827FF8301EfEAe6aB7aB081d75f11";

async function main() {

  contract = await connectContract(contractName, contractAddr)
  await contract.delPartner(partner)
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