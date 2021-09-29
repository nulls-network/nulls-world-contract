const { BigNumber } = require("@ethersproject/bignumber");
const hre = require("hardhat")
const fs = require("fs");

const addressList = [
    "0x6985E42F0cbF13a48b9DF9Ec845b652318793642",
]

//ntw奖励金额
const nwtAmount = 210000;


//npx hardhat run scripts/deploy-ido.js
async function main() {
    const [owner] = await hre.ethers.getSigners();
    console.log(owner.address)
    console.log("deploy start")
    const stakingToken = await deployErc20("USDC", "USDC");

    const nwt = await deployErc20("NWT", "NWT");

    const factory = "0xe544026845d1ee29cf74fe706cc9661be7fd9510";
    const IDO = await hre.ethers.getContractFactory("IdoCore");
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
}

async function deployErc20(name, symbol) {
    const ERC20 = await hre.ethers.getContractFactory("IdoToken");
    const erc20 = await ERC20.deploy(name, symbol);
    await erc20.deployed();
    console.log(`erc20 address>> ${erc20.address}`);
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




main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });