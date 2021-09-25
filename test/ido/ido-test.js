const { BigNumber } = require("@ethersproject/bignumber");
const hre = require("hardhat")

const approveAmount = BigNumber.from(10).pow(25);
///npx hardhat run test/ido/ido-test.js 

const contractName = "IdoCore";
const address = "0x88ccAc868f0d06c25c617bFAddD8aFE769087E22";
const idoToken = "IdoToken";
const future = BigNumber.from("1643738522"); // 2022/2/2
const past = BigNumber.from("1622394922");   // 2021/9/24

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
  const { staking, ido, owner } = await getData();
  const allowance = await staking.allowance(owner.address, ido.address);
  console.log(allowance)
  if (allowance.isZero()) {
    await (await staking.approve(ido.address, approveAmount)).wait();
  }
  const stakingAmount = BigNumber.from(10).pow(6).mul(10000);
  const stakeTx = await (await ido.stake(stakingAmount)).wait();
  console.log(stakeTx.transactionHash);
  console.log("=====================1")
  await addLiquidity();
  console.log("=====================2")
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
async function getRewardLP() {
  const { staking, ido, owner } = await getData();
  console.log(await ido.getRewardLP(owner.address))
}
async function rewardTime() {
  const { staking, ido, owner } = await getData();
  console.log(await ido.rewardTime(owner.address))
}

async function pairFor() {
  const { staking, ido, owner } = await getData();
  const aa = await ido.StakingToken();
  const bb = await ido.RewardsToken();
  console.log(await ido.pairFor(aa, bb));
}

async function rateOf() {
  const { staking, ido, owner } = await getData();
  console.log(await ido.rateOf(owner.address))
}

async function rateOf() {
  const { staking, ido, owner } = await getData();
  console.log(await ido.rateOf(owner.address))
}




let connected = {

}
async function connectContract(contractName, contractAddress) {
  if (contractAddress == connected[contractAddress]) {
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
