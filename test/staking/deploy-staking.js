const { BigNumber } = require("@ethersproject/bignumber");
const hre = require("hardhat")
const fs = require("fs");
const { erc20Name, contractName } = require("./config.json");

// npx hardhat clean && npx hardhat run test/staking/deploy-staking.js
const addressList = [
    "0x6985E42F0cbF13a48b9DF9Ec845b652318793642",
]
const startTime = 1630425600; //2021-9-1
async function main() {
    const [owner] = await hre.ethers.getSigners();
    console.log("deploy start");
    // const stakingToken = await deployErc20(["USDC", "USDC", 6]);
    const StakingCore = await hre.ethers.getContractFactory(contractName);
    const constructor = [startTime, "0xdC80db2c7fF47F790f29692f538b0cDAf0dA853B", "0xdC80db2c7fF47F790f29692f538b0cDAf0dA853B"];
    const staking = await StakingCore.deploy(...constructor);
    await staking.deployed();
    console.log("staking address>>", staking.address);
    // update(staking.address, stakingToken.address);
    await verify(staking.address, constructor)
}

async function deployErc20(constructor) {
    const [owner] = await hre.ethers.getSigners();
    const ERC20 = await hre.ethers.getContractFactory(erc20Name);
    const erc20 = await ERC20.deploy(...constructor);
    await erc20.deployed();
    console.log(`erc20 address>> ${erc20.address}`);
    await (await erc20.mint(owner.address, BigNumber.from(10).pow(25))).wait();
    for (const key of addressList) {
       await( await erc20.mint(key, BigNumber.from(10).pow(25))).wait();
    }
    // verify(erc20.address, constructor);
    return erc20;

}

const filePath = "./test/staking/config.json";
function readJsonFromFile() {
    let rawdata = fs.readFileSync(filePath)
    return JSON.parse(rawdata)
}

function writeJosnToConfigFile(data) {
    console.log("写入配置文件")
    fs.writeFileSync(filePath, JSON.stringify(data, null, 4));
}

function update(address, stakingToken) {
    let data = readJsonFromFile()
    data.address = address;
    data.stakingAddress = stakingToken;
    writeJosnToConfigFile(data);
}

async function verify(address, constructor) {
    // await hre.run("verify:verify", {
    //     address: address,
    //     constructorArguments: constructor,
    // });
}


main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });