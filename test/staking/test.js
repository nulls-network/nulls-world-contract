const { BigNumber } = require("@ethersproject/bignumber");
const hre = require("hardhat")
const { address, contractName, erc20Name, stakingToken, rewardsToken } = require("./config.json");


// npx hardhat run test/staking/test.js
async function main() {


  /**
   * 操作   
   */
  // 锁仓 ( index =0 ,amount = 10000)
  // 默认配置 0：活期  1：14天 2：28天
  await stake();

  // todo 测试方法 添加奖励 正式会删除
  // await test();


  // 领取奖励 (day = 0)
  // await getReward();

  //活期提现 (inde = 0, amount = 5000)
  // await withdraw();


  /**
   * 查询   
   */

  // //最新奖励下标
  // await bonusRecordLength();

  //计算分红 (account,index)
  // await earned();

  //查询份额  (account) 
  // await balanceOf();

  // 存款金额 (account)
  // await voucher();

  //总质押金额
  // await totalSupply();
  //总奖励金额
  // await totalRewards();

  //每天奖励 (index = 0) 
  // await bonusRecord();




}

async function test(erc20, amount = 10000) {
  const { staking, token, rewards,owner } = await getData();
  erc20 = erc20 ? erc20 : rewards;
  const value = await getErc20Value(rewards.address, amount);
  await approve(rewards.address, staking.address);
  const tx = await (await staking.test(rewards.address, value)).wait();
  console.log("test: ", tx.transactionHash);
}


// 锁仓
async function stake(index = 0, amount = 10000) {
  const { staking, token, owner } = await getData();
  await approve(token.address, staking.address);
  const value = await getErc20Value(token.address, amount);
  const tx = await (await staking.stake(index, value)).wait();
  console.log("stake: ", tx.transactionHash);
}



// 领取奖励
async function getReward(inde = 0) {
  const { staking, token, owner } = await getData();
  const tx = await (await staking.getReward(inde)).wait();
  console.log("getReward: ", tx.transactionHash);
}

// 提现
async function withdraw(inde = 0, amount = 5000) {
  const { staking, token, owner } = await getData();
  const value = await getErc20Value(token.address, amount);
  const tx = await (await staking.withdraw(inde, value)).wait();
  console.log("withdraw: ", tx.transactionHash);
}





// 设置定期数据
async function notifyInterest(index = 99999, day, rate, open = true) {

  // const { staking, token, owner } = await getData();
  // const tx = await (await staking.setCoefficient(time, coefficient)).wait();
  // console.log("setCoefficient: ", tx.transactionHash);
}



// 更新每日奖励
async function notifyBonus() {
  const { staking, token, owner } = await getData();
  const tx = await (await staking.notifyBonus()).wait();
  console.log("notifyRewards: ", tx.transactionHash);
}


// -----------------查询

//查询质押数据
async function voucher(account, index = 0,) {
  const { staking, token, owner } = await getData();
  account = account ? account : owner.address;
  const data = await staking.Voucher(account, index);
  console.log("Voucher: ", data);
}



//总质押金额
async function totalSupply() {
  const { staking, token, owner } = await getData();
  const data = await staking.TotalSupply();
  console.log("TotalSupply: ", data);
}


//总奖励金额 
async function totalRewards() {
  const { staking, token, owner } = await getData();
  const data = await staking.TotalRewards();
  console.log("TotalRewards: ", data);
}

//每日奖励
async function bonusRecord(index = 0) {
  const { staking, token, owner } = await getData();
  const data = await staking.BonusRecord(index);
  console.log("BonusRecord: ", data);
}

//最新奖励天数
async function bonusRecordLength(index = 0) {
  const { staking, token, owner } = await getData();
  const data = await staking.bonusRecordLength();
  console.log("bonusRecordLength: ", data);
}

//查询份额
async function balanceOf(account) {
  const { staking, token, owner } = await getData();
  account = account ? account : owner.address;
  const data = await staking.BalanceOf(account);
  console.log("BalanceOf: ", data);
}


async function earned(account, index = 0) {
  const { staking, token, owner } = await getData();
  account = account ? account : owner.address;
  const data = await staking.earned(account, index);
  console.log("earned: ", data);
}



function getTime(day) {
  return BigNumber.from(day).mul(86400);
}



async function getData() {
  const [owner] = await hre.ethers.getSigners();
  const staking = await connectContract(contractName, address);
  const token = await connectContract(erc20Name, stakingToken);
  const token2 = await connectContract(erc20Name, rewardsToken);
  data = {
    staking: staking,
    token: token,
    owner: owner,
    rewards: token2,
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
  return BigNumber.from(10).pow(decimals).mul(amount);
}



async function mint(address, to, amount) {
  erc20 = await connectContract(erc20Name, address);
  const value = await getErc20Value(address, amount);
  const tx = await (await erc20.mint(to, value)).wait();
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