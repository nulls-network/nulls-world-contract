const hre = require("hardhat")
const eth = require("ethers");
const { ethers } = require("hardhat");
const httpUtils = require("./httpUtils");

// 买蛋测试脚本,使用ht-testnet-user1测试
// npx hardhat run test/rank/newRank.js --network ht-testnet-user1

const contractName = "NullsRankManager";
const contractAddr = "0xeE156C0d169eb3B6b3Cde3BBF306c87e3afe65be";


const buyEggTokenContractName = "NullsERC20Token";
const buyEggTokenAddr = "0x6aA7CF4F83c6a88cABD93b40D47E7144311882B8";
const transferProxy = "0x3Cc1Ad4766c8b4D8a21B233Bae4Ef55c30139Ebd";

async function createRing() {

    let tokenContract = await connectContract(buyEggTokenContractName, buyEggTokenAddr);
    ret = await tokenContract.approve(transferProxy, 1000 * 10000000);
    await ret.wait();

    //创建擂台 
    let ringManager_contrcat = await connectContract(contractName, contractAddr);
    let creator = '0x6985E42F0cbF13a48b9DF9Ec845b652318793642';
    let petId = 320;
    let addressToken = '0x6aA7CF4F83c6a88cABD93b40D47E7144311882B8';
    let multiple = 5;

    let nonce = await ringManager_contrcat.nonces(creator);

    //   let playUser = await new ethers.Wallet('0x4a80ed77cc0d5dc214c5f358fd0fc49c0ed9926e178c170b0491f0770edbc530');
    const [playUser] = await hre.ethers.getSigners();

    const abiCoder = new ethers.utils.AbiCoder();
    const bytesData = abiCoder.encode(['string', 'uint', 'address', 'uint8', 'uint256', ' uint256'],
        ["nulls.online-play", petId, addressToken, multiple, nonce, 256]);

    const sign = await playUser.signMessage(ethers.utils.arrayify(ethers.utils.keccak256(bytesData)))
    const s1 = ethers.utils.splitSignature(sign);

    console.log("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");
    console.log("s1 ======", s1);
    let data = {
        owner_address: creator,
        pet_id: petId,
        token: addressToken,
        multiple: multiple,
        r: s1.r,
        s: s1.s,
        v: s1.v
    }
    console.log(data);
    let ccc = await httpUtils.post("http://172.17.150.209:7001/ring/createRing", data);
    console.log(ccc);
}

async function connectContract(contractName, contractAddress) {
    const [owner] = await hre.ethers.getSigners();
    let contract = await hre.ethers.getContractAt(contractName, contractAddress, owner)

    console.log(`connected ${contractName} address is : ${contract.address}`)
    return contract;
}

async function main() {
    await createRing();
}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });