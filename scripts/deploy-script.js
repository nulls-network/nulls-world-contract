const hre = require("hardhat");

async function main() {


  //部署第一个petToken
  const pet = await petToken() 
  const egg = await eggToken()

  const core = await mainCore()
  const eggMng = await eggManager()



}

async function deployContract( contractName , ... args ) {
  const Entity = await hre.ethers.getContractFactory( contractName )
  const entity = await Entity.deploy( ...args )

  await entity.deployed()

  console.log(` ${contractName} deployed to : ${entity.address} ${args}`)

  return entity 
}

async function mainCore() {
  const router = ""   // Router address
  deployContract("NullsWorldCore" , router )
}

async function eggManager(){
  deployContract("NullsEggManager")
}

async function petToken() {
  deployContract("NullsPetToken")
}

async function eggToken() {
  deployContract("NullsEggToken")
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
