const { BigNumber } = require("@ethersproject/bignumber");
const hre = require("hardhat")
const { address, contractName, erc20Name, stakingToken, rewardsToken } = require("./config.json");


// npx hardhat run test/ido/test.js 

async function main() {

  // ----------------- 操作
  // 抵押
  await stake();

  // 设置参数 （minimum：最低认购金额）
  // await setData();

  // 设置时间
  // await setPeriodFinish();

  //   添加流动性
  // await addLiquidity();

  // 领取奖励
  // await getReward();

  // staking兑换rewards
  // await swapStaking();

  // rewards兑换staking
  // await swapRewards();

  // ------------------- 查询

  //查询占比
  // await rateOf()

  //查询余额
  // await balanceOf();

  //查询总金额
  // await totalSupply();

  //已领取lp
  // await receivedLP();

  //最少认购金额
  // await minimumStaking();

}
// -----------操作
async function stake(amount = 20000) {
  const { staking, ido, owner } = await getData();
  await approve(staking.address, ido.address);
  const value = await getErc20Value(staking.address, amount);
  const stakeTx = await (await ido.stake(value)).wait();
  console.log("stake: ", stakeTx.transactionHash);
}


//修改时间 （管理员）
async function setPeriodFinish(time = 1622394922) {
  const { staking, ido, owner } = await getData();

  const tx = await (await ido.setPeriodFinish(time)).wait();
  console.log("setPeriodFinish: ", tx.transactionHash);
}

//设置参数 （minimum：最低认购金额） （管理员）
async function setData(minimum = 100, target = 21000) {
  const { staking, ido, owner, rewards } = await getData();


  const stakingValue = await getErc20Value(staking.address, minimum);
  const rewardsValue = await getErc20Value(rewards.address, target);

  const tx = await (await ido.setData(stakingValue, rewardsValue)).wait();
  console.log("setData: ", tx.transactionHash);
}

//添加流动性  （管理员）
async function addLiquidity() {
  const { staking, ido, owner } = await getData();
  let periodFinish = await ido.PeriodFinish();
  periodFinish = periodFinish.mul(1000);
  const now = BigNumber.from(new Date().getTime());
  if (now.lt(periodFinish)) {
    await setPeriodFinish()
  }
  const tx = await (await ido.addLiquidity()).wait();
  console.log("addLiquidity: ", tx.transactionHash);
}

//领取奖励
async function getReward() {
  const { staking, ido, owner } = await getData();
  const balnace = await ido.BalanceOf(owner.address);
  console.log("balance:", balnace)
  const tx = await (await ido.getReward()).wait();
  console.log("getReward: ", tx.transactionHash);
}

async function swapStaking(amountIn = 1000) {
  const { rewards, staking, ido, owner } = await getData();
  await swapExactTokensForTokens(amountIn, staking.address);
}

async function swapRewards(amountIn = 1000) {
  const { rewards, staking, ido, owner } = await getData();
  await swapExactTokensForTokens(amountIn, rewards.address);
}


//swap
async function swapExactTokensForTokens(amountIn, token) {
  const { rewards, staking, ido, owner } = await getData();
  await approve(token, ido.address);
  const value = getErc20Value(token,amountIn);
  const path = token == staking.address ? [staking.address, rewards.address] : [rewards.address, staking.address];
  await (await ido.swapExactTokensForTokens(value, 1, path, owner.address, 1695954712)).wait();
}


// ------------查询

//当前可领取的时间戳
async function rewardTime() {
  const { staking, ido, owner } = await getData();
  console.log("rewardTime: ", await ido.rewardTime(owner.address))
}

//已领取lp
async function receivedLP() {
  const { staking, ido, owner } = await getData();
  console.log("receivedLP: ", await ido.ReceivedLP())
}

//最少认购金额
async function minimumStaking() {
  const { staking, ido, owner } = await getData();
  console.log("minimumStaking: ", await ido.MinimumStaking())
}

// 当前时间戳的占比
async function rateOf() {
  const { staking, ido, owner } = await getData();
  console.log("rateOf: ", await ido.rateOf(owner.address))
}

// 查询地址余额
async function balanceOf() {
  const { staking, ido, owner } = await getData();
  console.log("balanceOf: ", await ido.BalanceOf(owner.address))
}

// 查询总抵押金额
async function totalSupply() {
  const { staking, ido, owner } = await getData();
  console.log("totalSupply: ", await ido.TotalSupply())
  await balanceOf()
}



async function pairFor() {
  const { staking, ido, owner } = await getData();
  const aa = await ido.StakingToken();
  const bb = await ido.RewardsToken();
  console.log("pairFor: ", await ido.pairFor(aa, bb));
}

async function getData() {
  const [owner] = await hre.ethers.getSigners();
  const ido = await connectContract(contractName, address);
  const staking = await connectContract(erc20Name, stakingToken);
  const rewards = await connectContract(erc20Name, rewardsToken);
  data = {
    rewards: rewards,
    staking: staking,
    ido: ido,
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

async function getErc20Value(address, amount) {
  const [owner] = await hre.ethers.getSigners();
  erc20 = await connectContract(erc20Name, address);
  const decimals = await erc20.decimals();
  console.log("decimals: ", decimals);
  return BigNumber.from(10).pow(decimals).mul(amount);
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
