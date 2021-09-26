const { BigNumber } = require("@ethersproject/bignumber");
const hre = require("hardhat")
const {address,contractName,erc20Name } = require("./config.json");

const approveAmount = BigNumber.from(10).pow(25);
///npx hardhat run test/ido/ido-test.js 

const past = 1622394922;

async function getData() {
  const [owner] = await hre.ethers.getSigners();
  const ido = await connectContract(contractName, address);
  const stakingAddress = await ido.StakingToken();
  const staking = await connectContract(erc20Name, stakingAddress);
  data = {
    staking: staking,
    ido: ido,
    owner: owner,
  }
  return data;

}
async function main() {

  // ----------------- 操作
  // 抵押
  await stake();

  //设置时间
  await setPeriodFinish();

  // 添加流动性
  await addLiquidity();

  // 领取奖励
  await getReward();

  // ------------------- 查询

  //查询占比
  // await rateOf()

  //查询余额
  // await balanceOf();

  //查询总金额
  // await totalSupply();

}
// -----------操作
async function stake() {
  const { staking, ido, owner } = await getData();
  const allowance = await staking.allowance(owner.address, ido.address);
  console.log("allowance: ", allowance)
  if (allowance.isZero()) {
    await (await staking.approve(ido.address, approveAmount)).wait();
  }
  const stakingAmount = BigNumber.from(10).pow(6).mul(20000);
  const stakeTx = await (await ido.stake(stakingAmount)).wait();
  console.log("stake: ", stakeTx.transactionHash);
}


//修改时间 （管理员）
async function setPeriodFinish(time = past) {
  const { staking, ido, owner } = await getData();

  const tx = await (await ido.setPeriodFinish(time)).wait();
  console.log("setPeriodFinish: ", tx.transactionHash);
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


// ------------查询

//当前可领取的时间戳
async function rewardTime() {
  const { staking, ido, owner } = await getData();
  console.log("rewardTime: ", await ido.rewardTime(owner.address))
}


async function pairFor() {
  const { staking, ido, owner } = await getData();
  const aa = await ido.StakingToken();
  const bb = await ido.RewardsToken();
  console.log("pairFor: ", await ido.pairFor(aa, bb));
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
