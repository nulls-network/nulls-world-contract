const hre = require("hardhat");

async function main() {

  const token = await token() 
  
}


async function token() {
  const NullsPet = await hre.ethers.getContractFactory("NullsPet")
  const pet = await NullsPet.deploy()

  await pet.deployed()

  console.log(`NullsPet deployed to : ${pet.address}`)

  return pet 
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
