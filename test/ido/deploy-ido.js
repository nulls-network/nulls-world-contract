const { BigNumber } = require("@ethersproject/bignumber");
const hre = require("hardhat")
const fs = require("fs");
const { erc20Name, contractName } = require("./config.json");

//npx hardhat clean && npx hardhat run test/ido/deploy-ido.js

const addressList = [
    "0x6985E42F0cbF13a48b9DF9Ec845b652318793642",
]
//ntw奖励金额
const nwtAmount = 210000;

async function main() {
    const [owner] = await hre.ethers.getSigners();
    console.log("deploy start")
    const stakingToken = await deployErc20("USDC", "USDC", 6);

    const nwt = await deployErc20("NWT", "NWT", 6);

    const factory = "0xe544026845d1ee29cf74fe706cc9661be7fd9510";
    const IDO = await hre.ethers.getContractFactory(contractName);
    const ido = await IDO.deploy(stakingToken.address, nwt.address, factory, 1640970061);
    await ido.deployed();
    await (await stakingToken.mint(owner.address, BigNumber.from(10).pow(25))).wait()
    for (const key of addressList) {
        await (await stakingToken.mint(key, BigNumber.from(10).pow(25))).wait()
    }
    await (await nwt.mint(owner.address, BigNumber.from(10).pow(25))).wait()
    console.log(`ido address>> ${ido.address}`);

    await nwt.mint(ido.address, BigNumber.from(10).pow(6).mul(nwtAmount));
    upAddress(ido.address, stakingToken.address, nwt.address);
    await verify(ido.address, [
        stakingToken.address,
        nwt.address,
        factory,
        1640970061,
    ]);
}

async function deployErc20(name, symbol, decimals) {
    const ERC20 = await hre.ethers.getContractFactory(erc20Name);
    const erc20 = await ERC20.deploy(name, symbol, decimals);
    await erc20.deployed();
    console.log(`erc20 address>> ${erc20.address}`);
    verify(erc20.address, [name, symbol, decimals]);
    return erc20;

}


const filePath = "./test/ido/config.json";
function readJsonFromFile() {
    let rawdata = fs.readFileSync(filePath)
    return JSON.parse(rawdata)
}
function writeJosnToConfigFile(data) {
    console.log("写入配置文件")
    fs.writeFileSync(filePath, JSON.stringify(data, null, 4));
}
function upAddress(address, stakingToken, rewardsToken) {
    let data = readJsonFromFile()
    data.address = address;
    data.stakingAddress = stakingToken;
    data.rewardsAddress = rewardsToken;
    writeJosnToConfigFile(data);
}

async function verify(address, constructor) {
    await hre.run("verify:verify", {
        address: address,
        constructorArguments: constructor,
    });
}




main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });