const hre = require("hardhat");

// router合约地址
const routerAddr = "0x10B1E40Eb8Fe6B7b1673140631f647Ab42160F83"

// 购买蛋的币种、Pk入场券币种
const erc20USDTAddr = "0x04F535663110A392A6504839BEeD34E019FdB4E0"

// 购买蛋的单价
const eggPrice = 1;
// pk入场券
const pkPrice = 10;

let petTokenAddr = ""
let eggTokenAddr = ""

const deployPetToken = true;
const deployeggToken = true;

// 游戏名称
const gameName = "Nulls"

// 开蛋场景名称
const eggMngName = "Nulls-OpenEgg";

// PK场景名称
const petPkName = "Nulls-Pk";

async function main() {

  if (deployPetToken) {
    await petToken() 
  }
  
  if (deployeggToken) {
    await eggToken()
  }

  let core = await mainCore()

  let eggMng = await eggManager(core)

  let ring = await ringManager(core)
  
  console.log("完成!")
}

async function deployContract( contractName , ... args ) {
  let Entity = await hre.ethers.getContractFactory( contractName )
  let entity = await Entity.deploy( ...args )

  await entity.deployed()

  console.log(` ${contractName} deployed to : ${entity.address} ${args}`)

  return entity 
}

async function mainCore() {
  let core = await deployContract("NullsWorldCore" , routerAddr )
    // 注册游戏
    let txHash = await core.registerGame(gameName)
    await txHash.wait()

  return core;
}

async function eggManager(core){
  
  let eggmanager = await deployContract("NullsEggManager")
  // 配置newItem白名单权限
  let txAddWhiteList = await core.addNewItemWhiteList(eggmanager.address)
  await txAddWhiteList.wait()

  // 设置eggToken和petToken
  await eggmanager.setPetToken(eggTokenAddr,petTokenAddr)

  // 设置购买宠物币种和金额
  await eggmanager.setBuyToken(erc20USDTAddr, eggPrice);

  // 设置代理，并创建场景
  let txHashSetProxy = await eggmanager.setProxy(core.address, eggMngName)
  await txHashSetProxy.wait()

  let sceneId = await eggmanager.getSceneId()
  console.log("eggmanager sceneId = ", sceneId)
}

async function petToken() {
  let pt = await deployContract("NullsPetToken")
  petTokenAddr = pt.address
}

async function eggToken() {
  let et = await deployContract("NullsEggToken")
  eggTokenAddr = et.address
}

async function ringManager(core) {
  
  let ring = await deployContract("NullsRingManager")

  // 配置newItem白名单权限
  let txAddWhiteList = await core.addNewItemWhiteList(ring.address)
  await txAddWhiteList.wait();

  // 配置支持的币种(测试，入场资金10U，开擂台花费50U/100U)
  let txHashAddRingToken = await ring.addRingToken(erc20USDTAddr, pkPrice)
  await txHashAddRingToken.wait()
  // 配置代理，并创建场景
  let txHashSetProxy = await ring.setProxy(core.address, petPkName)
  await txHashSetProxy.wait()
  // 配置pet合约地址
  let txHashSetPetToken = await ring.setPetToken(petTokenAddr)
  let waitRet = await txHashSetPetToken.wait()

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
