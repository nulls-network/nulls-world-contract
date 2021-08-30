const hre = require("hardhat");

async function main() {


  //部署第一个petToken
  // const pet = await petToken() 
  // const egg = await eggToken()

  const core = await mainCore()
  // const eggMng = await eggManager()



}

async function deployContract( contractName , ... args ) {
  const Entity = await hre.ethers.getContractFactory( contractName )
  const entity = await Entity.deploy( ...args )

  await entity.deployed()

  console.log(` ${contractName} deployed to : ${entity.address} ${args}`)

  return entity 
}

async function mainCore() {
  const router = "0xd1B60bcfc36fb062F08cb0430958C1bcC726812A"   // Router address
  await deployContract("NullsWorldCore" , router )
}

async function eggManager(){
  await deployContract("NullsEggManager")
}

async function petToken() {
  await deployContract("NullsPetToken")
}

async function eggToken() {
  await deployContract("NullsEggToken")
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
