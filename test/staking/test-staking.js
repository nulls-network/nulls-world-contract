const { BigNumber } = require("@ethersproject/bignumber");
const hre = require("hardhat")
const { address, contractName, erc20Name, stakingAddress } = require("./config.json");

// npx hardhat run test/staking/test-staking.js
async function main() {
  await stake();
}



// 锁仓
async function stake(amount = 10000) {
  const { staking, token, owner } = await getData();
  await approve(token.address, staking.address);
  const decimals = await getDecimals(token.address)
  const value = BigNumber.from(10).pow(decimals).mul(amount);
  const tx = await (await staking.stake(value, 0)).wait();
  console.log("stake: ", tx.transactionHash);
}

// 更新每日奖励
async function notifyRewards() {
  const { staking, token, owner } = await getData();
  const tx = await (await staking.notifyRewards()).wait();
  console.log("notifyRewards: ", tx.transactionHash);
}

// 领取系数奖励
async function getDayRewards(key) {
  const { staking, token, owner } = await getData();
  const tx = await (await staking.getDayRewards(key)).wait();
  console.log("getDayRewards: ", tx.transactionHash);
}

// 领取随存随取奖励
async function getReward(key) {
  const { staking, token, owner } = await getData();
  const tx = await (await staking.getReward()).wait();
  console.log("getReward: ", tx.transactionHash);
}

// 提现
async function withdraw(key) {
  const { staking, token, owner } = await getData();
  const tx = await (await staking.withdraw()).wait();
  console.log("withdraw: ", tx.transactionHash);
}





async function getData() {
  const [owner] = await hre.ethers.getSigners();
  const staking = await connectContract(contractName, address);
  const token = await connectContract(erc20Name, stakingAddress);
  data = {
    staking: staking,
    token: token,
    owner: owner,
  }
  return data;

}


async function approve(address, to) {
  const approveAmount = BigNumber.from(10).pow(25);
  const [owner] = await hre.ethers.getSigners();
  erc20 = await connectContract(erc20Name, address);
  const allowance = await erc20.allowance(owner.address, to);
  console.log("allowance: ", allowance)
  if (allowance.isZero()) {
    await (await erc20.approve(to, approveAmount)).wait();
  }
}

async function getDecimals(address) {
  const [owner] = await hre.ethers.getSigners();
  erc20 = await connectContract(erc20Name, address);
  const decimals = await erc20.decimals();
  console.log("decimals: ", decimals)
  return decimals;
}



let connected = {

}
async function connectContract(contractName, contractAddress) {
  if (connected[contractAddress]) {
    return connected[contractAddress]
  }
  const [owner] = await hre.ethers.getSigners();
  let contract = await hre.ethers.getContractAt(contractName, contractAddress, owner)
  connected[contractAddress] = contract;
  console.log(`connected ${contractName} address is : ${contract.address}`)
  return contract;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });