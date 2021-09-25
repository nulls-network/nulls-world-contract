const { BigNumber } = require("@ethersproject/bignumber");
const hre = require("hardhat")

const approveAmount = BigNumber.from(10).pow(25);
///npx hardhat run test/ido/ido-test.js 

const contractName = "IdoCore";
const address = "0x057a9BD42702Ef1105d5484005B76223b4AA2a5b";
const idoToken = "IdoToken";
const past = BigNumber.from("1622394922");

async function getData() {
  const [owner] = await hre.ethers.getSigners();
  const ido = await connectContract(contractName, address);
  const stakingAddress = await ido.StakingToken();
  const staking = await connectContract(idoToken, stakingAddress);
  data = {
    staking: staking,
    ido: ido,
    owner: owner,
  }
  return data;

}
async function main() {
  // const { staking, ido, owner } = await getData();
  // const allowance = await staking.allowance(owner.address, ido.address);
  // console.log("allowance: ", allowance)
  // if (allowance.isZero()) {
  //   await (await staking.approve(ido.address, approveAmount)).wait();
  // }
  // const stakingAmount = BigNumber.from(10).pow(6).mul(20000);
  // const stakeTx = await (await ido.stake(stakingAmount)).wait();
  // console.log(stakeTx.transactionHash);
  console.log("=====================1")
  await addLiquidity();
  console.log("=====================2")
  await rateOf()
  await getReward();
}


async function setDeadline(time) {
  const { staking, ido, owner } = await getData();
  if (time) {
    time = past;
  }
  const tx = await (await ido.setDeadline(time)).wait();
  console.log(tx.transactionHash);
}

async function addLiquidity() {
  const { staking, ido, owner } = await getData();
  let deadLine = await ido.Deadline();
  deadLine = deadLine.mul(1000);
  const now = BigNumber.from(new Date().getTime());
  if (now.lt(deadLine)) {
    await setDeadline(past)
  }
  const tx = await (await ido.addLiquidity()).wait();
  console.log(tx.transactionHash);
}

async function getReward() {
  const { staking, ido, owner } = await getData();
  const balnace = await ido.BalanceOf(owner.address);
  console.log("balance:", balnace)
  const tx = await (await ido.getReward()).wait();
  console.log(tx.transactionHash);
}
// ------------
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

async function rateOf() {
  const { staking, ido, owner } = await getData();
  console.log("rateOf: ", await ido.rateOf(owner.address))
}

async function balanceOf() {
  const { staking, ido, owner } = await getData();
  console.log("balanceOf: ", await ido.BalanceOf(owner.address))
}

async function totalSupply() {
  const { staking, ido, owner } = await getData();
  console.log("totalSupply: ", await ido.TotalSupply())
  await balanceOf()
}

async function secondRewards() {
  const { staking, ido, owner } = await getData();
  console.log("secondRewards: ", await ido.SecondRewards())
}

async function secondStaking() {
  const { staking, ido, owner } = await getData();
  console.log("secondStaking: ", await ido.SecondStaking())
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
