const { BigNumber } = require("@ethersproject/bignumber");
const hre = require("hardhat")
const { address, contractName, erc20Name, stakingToken } = require("./config.json");


// npx hardhat run test/staking/test.js
async function main() {
  /**
   * day=0 则活期 其他则定期：默认配置[14，28]
   */

  // ----操作
  // 锁仓 ( day =0 ,amount = 10000)   
  await stake();

  await test();

  // 领取奖励 (day = 0)
  // await getReward();

  //活期提现 day = 0, amount = 5000
  // await withdraw();

  // ------查询
  //查询份额  (account) 
  // await balanceOf();

  //活期金额 (account)
  // await voucher();
  // 定期金额 (key)  , key事件获取

  //总质押金额
  // await totalSupply();
  //总奖励金额
  // await totalRewards();

  //每天奖励 (index = 0) 
  await bonusRecord();




}

async function test(amount=10000){
  const { staking, token, owner } = await getData();
  const value = await getErc20Value(token.address, amount);
  const tx = await (await staking.test(token.address, value)).wait();
  console.log("test: ", tx.transactionHash);
}


// 锁仓
async function stake(day = 0, amount = 10000) {
  const { staking, token, owner } = await getData();
  await approve(token.address, staking.address);
  const value = await getErc20Value(token.address, amount);
  const time = getTime(day)
  const tx = await (await staking.stake(time, value)).wait();
  console.log("stake: ", tx.transactionHash);
}



// 领取奖励
async function getReward(day = 0) {
  const { staking, token, owner } = await getData();
  const time = getTime(day)
  const tx = await (await staking.getReward(time)).wait();
  console.log("getReward: ", tx.transactionHash);
}

// 提现
async function withdraw(day = 0, amount = 5000) {
  const { staking, token, owner } = await getData();
  const time = getTime(day)
  const value = await getErc20Value(token.address, amount);
  const tx = await (await staking.withdraw(time, value)).wait();
  console.log("withdraw: ", tx.transactionHash);
}





// 设置定期数据
async function setCoefficient(day = 14, coefficient = 1100) {
  const time = getTime(day)
  const { staking, token, owner } = await getData();
  const tx = await (await staking.setCoefficient(time, coefficient)).wait();
  console.log("setCoefficient: ", tx.transactionHash);
}



// 更新每日奖励
async function notifyRewards() {
  const { staking, token, owner } = await getData();
  const tx = await (await staking.notifyRewards()).wait();
  console.log("notifyRewards: ", tx.transactionHash);
}


// -----------------查询

//查询质押数据
async function voucher(day = 0, account) {
  const time = getTime(day)
  const { staking, token, owner } = await getData();
  account = account ? account : owner.address;
  const data = await staking.Voucher(time, account);
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

//查询份额
async function balanceOf(account) {
  const { staking, token, owner } = await getData();
  account = account ? account : owner.address;
  const data = await staking.BalanceOf(account);
  console.log("BalanceOf: ", data);
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

async function getErc20Value(address, amount) {
  const [owner] = await hre.ethers.getSigners();
  erc20 = await connectContract(erc20Name, address);
  const decimals = await erc20.decimals();
  console.log("decimals: ", decimals);
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