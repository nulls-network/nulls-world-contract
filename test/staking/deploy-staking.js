const { BigNumber } = require("@ethersproject/bignumber");
const hre = require("hardhat")
const fs = require("fs");
const { erc20Name, contractName } = require("./config.json");

// npx hardhat clean && npx hardhat run test/staking/deploy-staking.js
const addressList = [
    "0x6985E42F0cbF13a48b9DF9Ec845b652318793642",
    "0x84f09d4688c683e2Bb84Cb36CdeC22A288eF99de",
]
const startTime = 1630425600; //2021-9-1
async function main() {

    const [owner] = await hre.ethers.getSigners();
    console.log("deploy start");
    const stakingToken = await deployErc20(["stakingToken", "USDC", 6],true,true);
    const StakingCore = await hre.ethers.getContractFactory(contractName);
    const constructor = [startTime, stakingToken.address, stakingToken.address];
    const staking = await StakingCore.deploy(...constructor);
    await staking.deployed();
    console.log("staking address>>", staking.address);
    update(staking.address, stakingToken.address);
    await verify(staking.address, constructor)
}


async function deployErc20(constructor,noOverride,mint) {
    const json = readJsonFromFile();

    const contractAddress = json[constructor[0]];
    if (contractAddress && noOverride) {
        const [owner] = await hre.ethers.getSigners();
        let contract = await hre.ethers.getContractAt(erc20Name, contractAddress, owner);
        return contract;
    }
    const ERC20 = await hre.ethers.getContractFactory(erc20Name);
    const erc20 = await ERC20.deploy(...constructor);
    await erc20.deployed();
    console.log(`erc20 address>> ${erc20.address}`);
    if(mint){
        await (await erc20.mint(owner.address, BigNumber.from(10).pow(constructor[2] + 8))).wait();
        for (const key of addressList) {
            await (await erc20.mint(key, BigNumber.from(10).pow(constructor[2] + 9 ))).wait();
            console.log("mint>>>:",key)
        }
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
    data.stakingToken = stakingToken;
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