/// 合约一键部署并初始化脚本
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

// 成为合伙人的条件，以下满足一个即可
const minBuyEggNumber = 3
const minInviteNumber = 3


// 预售活动奖励的 token 总数
const promotionTotal = 210000 * 1000000
// 预售活动开始时间(UTC时间)
const promotionStartTime = new Date(Date.UTC(2021, 9 - 1, 9, 0, 0, 0)).getTime() / 1000
// const promotionStartTime = new Date(Date.UTC(year, month - 1, day, hour, minute, second))
// 预售活动结束时间
const promotionEndTime = new Date(Date.UTC(2021, 9 - 1, 25, 0, 0, 0)).getTime() / 1000
// 预售期蛋购买者和其三级关系奖励金额
const buyer = 40 * 1000000
const one = 30 * 1000000
const two = 20 * 1000000
const three = 10 * 1000000

let rwaJsonData;

async function main() {
  
  readJsonFromFile()

  // 用于测试期间支付购买宠物、pk的token
  let testC20 = await c20();
  let petT = await petToken() 
  let eggT = await eggToken()

  await petMarket(petT, testC20)

  let core = await mainCore()

  let eggM = await eggManager(core, petT, eggT, testC20)

  await ringManager(core,testC20, petT)
  
  let mainToken = await nullsToken()
  let nullsInvite = await invite()
  await promotion(nullsInvite, eggM, mainToken)

  console.log(rwaJsonData)
  writeJosnToConfigFile()
  console.log("完成!")
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

  return obj
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

// 跟随nulls发行的代币，主要用途是锁仓获取奖池奖金，获取方式是通过活动获取
async function nullsToken() {
  const contractAddresskey = "NullsMainToken"
  const contractName = "NullsWorldToken"
  let obj = await connectOrDeployContract(contractName, contractAddresskey)
  // obj.contract.setBeginTime()
  const [owner] = await hre.ethers.getSigners()
  await obj.contract.modifierOper(owner.address)
  return obj
}

async function invite() {
  const contractAddresskey = "NullsInvite"
  const contractName = "NullsInvite"
  let obj = await connectOrDeployContract(contractName, contractAddresskey)

  // 设置成为合伙人的条件
  let invite = obj.contract
  await invite.setPartnerCondition(minBuyEggNumber, minInviteNumber)

  return obj
}

async function promotion(nullsInvite, eggM, mainToken) {
  const contractAddresskey = "NullsPromotion"
  const contractName = "NullsPromotion"
  let obj = await connectOrDeployContract(contractName, contractAddresskey)

  if (eggM.flag || obj.flag) {
    // 对购买蛋操作设置后置处理器
    await eggM.contract.setAfterProccess(obj.contract.address)
  }

  if (nullsInvite.flag || obj.flag) {
    // 设置invite的活动合约
    await nullsInvite.contract.addPromotionContract(obj.contract.address)
  }

  if (mainToken.flag || obj.flag) {
    // 释放token给活动合约
    await mainToken.contract.mint(obj.contract.address, promotionTotal)
  }

  await obj.contract.setReward(mainToken.contract.address, promotionTotal, promotionStartTime, promotionEndTime)
  await obj.contract.setBaseInfo(nullsInvite.contract.address, eggM.contract.address)
  await obj.contract.setRewardValue(buyer, one, two, three)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
