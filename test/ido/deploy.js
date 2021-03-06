const { BigNumber } = require("@ethersproject/bignumber");
const hre = require("hardhat")
const fs = require("fs");
const { erc20Name, contractName } = require("./config.json");

//  npx hardhat clean ; npx hardhat run test/ido/deploy.js

let addressList = [
    "0x6985E42F0cbF13a48b9DF9Ec845b652318793642",
    "0x8C47494c675333dc613547600432d53ae78b272f",
    "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    "0x84f09d4688c683e2Bb84Cb36CdeC22A288eF99de"
]
//ntw奖励金额
const nwtAmount = 210000;

async function main() {
    const [owner] = await hre.ethers.getSigners();
    console.log("deploy start")
    const stakingToken = await deployErc20(["stakingToken", "USDC", 6],true,true);

    const nwt = await deployErc20(["rewardsToken", "NWT", 6],false,false);

    const factory = "0xe544026845d1ee29cf74fe706cc9661be7fd9510";
    const IDO = await hre.ethers.getContractFactory(contractName);
    const ido = await IDO.deploy(stakingToken.address, nwt.address, factory, 1640970061);
    await ido.deployed();
    console.log(`ido address>> ${ido.address}`);
    const nwtTotalSupply=BigNumber.from(10).pow(6).mul(21000000-nwtAmount);
    await (await nwt.mint(owner.address, nwtTotalSupply)).wait();
    await (await nwt.mint(ido.address, BigNumber.from(10).pow(6).mul(nwtAmount))).wait();
    upAddress(ido.address, stakingToken.address, nwt.address);
    await verify(ido.address, [
        stakingToken.address,
        nwt.address,
        factory,
        1640970061,
    ]);
}

async function getDecimals(address) {
    const [owner] = await hre.ethers.getSigners();
    erc20 = await connectContract(erc20Name, address);
    const decimals = await erc20.decimals();
    console.log("decimals: ", decimals)
    return BigNumber.from(10).pow(decimals);
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
    data.stakingToken = stakingToken;
    data.rewardsToken = rewardsToken;
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