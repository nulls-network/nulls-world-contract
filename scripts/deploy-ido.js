const { BigNumber } = require("@ethersproject/bignumber");
const hre = require("hardhat")
const fs = require("fs");
const addressList = [
    "0x6985E42F0cbF13a48b9DF9Ec845b652318793642",
]
//npx hardhat run scripts/deploy-ido.js
async function main() {
    const [owner] = await hre.ethers.getSigners();
    console.log(owner.address)
    console.log("deploy start")
    const stakingToken = await deployErc20("IDO Staking", "IST");
    await (await stakingToken.mint(owner.address, BigNumber.from(10).pow(25))).wait()
    for (const key of addressList) {
        await (await stakingToken.mint(key, BigNumber.from(10).pow(25))).wait()
    }
    const rewardsTokne = await deployErc20("IDO Rewards", "IRT");
    await (await rewardsTokne.mint(owner.address, BigNumber.from(10).pow(25))).wait()
    const router = "0xF10391fE0c5845166E8768BFEc172B112014bDbA";
    const IDO = await hre.ethers.getContractFactory("IdoCore");
    const ido = await IDO.deploy(stakingToken.address, rewardsTokne.address, router, 1640970061);
    await ido.deployed();
    await rewardsTokne.mint(ido.address, BigNumber.from(10).pow(6).mul(210000));

    console.log(`ido address>> ${ido.address}`);
}

async function deployErc20(name, symbol) {
    const ERC20 = await hre.ethers.getContractFactory("IdoToken");
    const erc20 = await ERC20.deploy(name, symbol);
    await erc20.deployed();
    console.log(`erc20 address>> ${erc20.address}`);
    return erc20;

}


main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });