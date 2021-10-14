const { BigNumber } = require("@ethersproject/bignumber");
const hre = require("hardhat")
const { address, contractName, erc20Name, stakingToken } = require("./config.json");


// npx hardhat run test/staking/test-staking.js
async function main() {

  // ----操作
  // 活期锁仓
  // await stake();
  // 定期锁仓 默认14天 
  // await stakeDay();

  // //领取活期奖励
  // await getReward();

  //领取定期奖励，key事件获取
  await getDayRewards();

}


// 锁仓
async function stake(amount = 10000) {
  const { staking, token, owner } = await getData();
  await approve(token.address, staking.address);
  const decimals = await getDecimals(token.address)
  const value = decimals.mul(amount);
  const tx = await (await staking.stake(value)).wait();
  console.log("stake: ", tx.transactionHash);
}

// 定期锁仓 默认14天
async function stakeDay(day = 14,amount = 10000 ) {
  const { staking, token, owner } = await getData();
  await approve(token.address, staking.address);
  const decimals = await getDecimals(token.address)
  const value = decimals.mul(amount);
  const time= getTime(day)
  const tx = await (await staking.stakeDay(time, value)).wait();
  console.log("stakeDay: ", tx.transactionHash);
}

// 领取定期奖励
async function getDayRewards(key) {
  if(!key){
    console.log("key not null");
    return;
  }
  const { staking, token, owner } = await getData();
  const tx = await (await staking.getDayRewards(key)).wait();
  console.log("getDayRewards: ", tx.transactionHash);
}

// 领取活期奖励
async function getReward() {
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



// 默认14天
async function setCoefficient(time = day14, coefficient = 1100) {
  const { staking, token, owner } = await getData();
  const tx = await (await staking.setCoefficient(time, coefficient)).wait();
  console.log("stake: ", tx.transactionHash);
}



// 更新每日奖励
async function notifyRewards() {
  const { staking, token, owner } = await getData();
  const tx = await (await staking.notifyRewards()).wait();
  console.log("notifyRewards: ", tx.transactionHash);
}




async function voucher(key) {
  const { staking, token, owner } = await getData();
  const data = await staking.Voucher(owner.address);
  console.log("voucher: ", data);
}


function getTime(day) {
  return BigNumber.from(day).mul(86400);
}


async function getData() {
  const [owner] = await hre.ethers.getSigners();
  const staking = await connectContract(contractName, address);
  const token = await connectContract(erc20Name, stakingToken);
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
  console.log("decimals: ", decimals);
  return BigNumber.from(10).pow(decimals);
}


async function mint(address, to, amount) {
  const [owner] = await hre.ethers.getSigners();
  erc20 = await connectContract(erc20Name, address);
  const decimals = getDecimals(address);
  const tx = await (await erc20.mint(to, (await decimals).mul(amount))).wait();
  console.log("mint: ", tx.transactionHash);
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