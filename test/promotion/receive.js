const hre = require("hardhat")

// 奖励领取测试脚本
// npx hardhat run test/promotion/receive.js --network ht-testnet-user1

const contractName = "NullsPromotion";
const contractAddr = "0x819Cbfe21b12f8f2c0C16C6A144Dbe4Afb94ED92";

async function main() {

  contract = await connectContract(contractName, contractAddr)
  const [owner] = await hre.ethers.getSigners();
  const value = await contract.UserRewards(owner.address)
  console.log("待领取奖励: ", hex2int(value._hex))
  ret = await contract.receiveReward()
  await ret.wait()
  console.log("领取成功")
}

function hex2int(hex) {
  var len = hex.length, a = new Array(len), code;
  for (var i = 2; i < len; i++) {
      code = hex.charCodeAt(i);
      if (48<=code && code < 58) {
          code -= 48;
      } else {
          code = (code & 0xdf) - 65 + 10;
      }
      a[i] = code;
  }
   
  return a.reduce(function(acc, c) {
      acc = 16 * acc + c;
      return acc;
  }, 0);
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
