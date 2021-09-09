/// 合约一键部署脚本并初始化脚本
/// 如果想要部署某一合约，请在config.json文件中将该合约地址对应的value值设置为""
/// 如果合约地址存在，则不进行部署操作而是进行连接操作
const hre = require("hardhat")
const fs = require("fs");
const { exit } = require("process");

const configFile = "./scripts/config.json"

const prefixKey = "contrat_address"

// router合约是否是新部署的，如果是的话，游戏和item一定需要重新注册
const newRouterContractFlag = false

// 购买蛋的单价
const eggPrice = 1 * 1000000
// pk入场券
const pkPrice = 10 * 1000000

// 游戏名称
const gameName = "Nulls"

// 开蛋场景名称
const eggMngName = "Nulls-OpenEgg"

// PK场景名称
const petPkName = "Nulls-Pk"

// 普通宠物休息时间
const generalPetRestTime = 1

let rwaJsonData;

async function main() {
  
  readJsonFromFile()

  let testC20 = await c20();
  let petT = await petToken() 
  let eggT = await eggToken()

  await petMarket(petT, testC20)

  let core = await mainCore()

  await eggManager(core, petT, eggT, testC20)

  await ringManager(core,testC20, petT)
  
  console.log(rwaJsonData)
  writeJosnToConfigFile()
  console.log("完成!")
  exit(0)
}

function readJsonFromFile() {
  let rawdata = fs.readFileSync(configFile)
  rwaJsonData = JSON.parse(rawdata)
}

function writeJosnToConfigFile() {
  console.log("写入配置文件")
  let data = JSON.stringify(rwaJsonData, null, 4);
  fs.writeFileSync(configFile, data);
}

async function deployContract( contractName , args ) {
  let Entity = await hre.ethers.getContractFactory( contractName )
  let entity = await Entity.deploy( ...args )

  await entity.deployed()

  console.log(` ${contractName} deployed to : ${entity.address} ${args}`)

  return entity 
}

async function connectContract(contractName, contractAddress) {
  const [owner] = await hre.ethers.getSigners();
  let contract = await hre.ethers.getContractAt( contractName ,contractAddress, owner);

  console.log(`connected ${contractName} address is : ${contract.address}`)
  return contract;
}

function isEmpty(key) {
  return rwaJsonData[prefixKey][key] === '' || rwaJsonData[prefixKey][key] === null
}

async function connectOrDeployContract(contractName, contractAddressKey, ... args) {
  let c = isEmpty(contractAddressKey) ? await deployContract(contractName, args) : await connectContract(contractName, rwaJsonData[prefixKey][contractAddressKey])
  let isNewContract = isEmpty(contractAddressKey);
  rwaJsonData[prefixKey][contractAddressKey] = c.address
  return {
    contract: c,
    flag: isNewContract      
  }
}

async function petMarket(petToken, nullsErc20TestToken) {
  const contractAddresskey = "NullsWorldMarket"
  const contractName = "NullsWorldMarket"
  let obj = await connectOrDeployContract(contractName, contractAddresskey)
  let market = obj.contract
  await market.setPetToken(petToken.contract.address)
  await market.setSupportedToken(rwaJsonData[prefixKey]["USDT"])
  await market.setSupportedToken(nullsErc20TestToken.contract.address)
}

async function c20() {
  const contractAddresskey = "NullsErc20TestToken"
  const contractName = "NullsERC20Token"
  return await connectOrDeployContract(contractName, contractAddresskey)
}

async function mainCore() {
  const contractAddresskey = "worldCore_address"
  const contractName = "NullsWorldCore"

  let obj = await connectOrDeployContract(contractName, contractAddresskey , rwaJsonData[prefixKey]["router_address"] )
  let core = obj.contract
  let flag = obj.flag

  // router合约重新部署过或core合约重新部署过，都需要重新注册游戏
  if (newRouterContractFlag || flag) {
    // 注册游戏
    let txHash = await core.registerGame(gameName)
    await txHash.wait()
  }
  return obj;
}

async function eggManager(core, petT, eggT, testC20){

  const contractAddresskey = "EggManager_address"
  const contractName = "NullsEggManager"
  
  let obj = await connectOrDeployContract(contractName, contractAddresskey )
  let eggmanager = obj.contract;

  if (petT.falg || obj.flag) {
    // 配置petToken operator
    await petT.contract.modifyOper(eggmanager.address)
  }
  
  if (eggT.falg || obj.flag) {
    // 配置eggToken operator
    await eggT.contract.modifierOper(eggmanager.address)
  }
  
  if (core.flag || obj.flag) {
    // 配置newItem白名单权限
    let txAddWhiteList = await core.contract.addNewItemWhiteList(eggmanager.address)
    await txAddWhiteList.wait()
  }
  
  if (obj.flag || petT.flag || eggT.flag) {
    // 设置eggToken和petToken
    await eggmanager.setPetToken(eggT.contract.address, petT.contract.address)
  }
  
  // 设置购买宠物币种和金额
  await eggmanager.setBuyToken(testC20.contract.address, eggPrice);
  await eggmanager.setBuyToken(rwaJsonData[prefixKey]["USDT"], eggPrice);

  // eggManager合约重新部署过 或 core合约重新部署过 或 router合约重新部署过，都需要重新注册场景
  if (obj.flag || core.flag || newRouterContractFlag) {
    // 设置代理，并创建场景
    let txHashSetProxy = await eggmanager.setProxy(core.contract.address, eggMngName)
    await txHashSetProxy.wait()
  }

  let sceneId = await eggmanager.getSceneId()
  console.log("eggmanager sceneId = ", sceneId)
}

async function petToken() {
  const contractAddresskey = "petToken_address"
  const contractName = "NullsPetToken"
  return await connectOrDeployContract(contractName, contractAddresskey)
}

async function eggToken() {
  const contractAddresskey = "EggToken_address"
  const contractName = "NullsEggToken"
  return await connectOrDeployContract(contractName, contractAddresskey)
}

async function ringManager(core, testC20, petT) {
  const contractAddresskey = "RingManager_address"
  const contractName = "NullsRankManager"
  let obj = await connectOrDeployContract(contractName, contractAddresskey)
  let ring = obj.contract

  if (core.flag || obj.flag) {
    // 配置newItem白名单权限
    let txAddWhiteList = await core.contract.addNewItemWhiteList(ring.address)
    await txAddWhiteList.wait();
  }

  // 配置支持的币种(测试，入场资金10U，开擂台花费50U/100U)
  let txHashAddRingToken = await ring.addRankToken(testC20.contract.address, pkPrice)
  await txHashAddRingToken.wait()
  txHashAddRingToken = await ring.addRankToken(rwaJsonData[prefixKey]["USDT"], pkPrice)
  await txHashAddRingToken.wait()

  if (obj.flag || core.flag || newRouterContractFlag) {
    // 配置代理，并创建场景
    let txHashSetProxy = await ring.setProxy(core.contract.address, petPkName)
    await txHashSetProxy.wait()
  }
  
  if (obj.flag || petT.flag) {
    // 配置pet合约地址
    let txHashSetPetToken = await ring.setPetToken(petT.contract.address)
    let waitRet = await txHashSetPetToken.wait()
  }  

  // 配置普通宠物休息时间
  await ring.setRestTime(generalPetRestTime)

  let sceneId = await ring.getSceneId()
  console.log("ringManager sceneId = ", sceneId)

  return ring
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
