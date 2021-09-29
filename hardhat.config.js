require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.4",
  defaultNetwork: "ht-testnet",
  etherscan: {
    // Your API key for Etherscan
    url: "https://api-testnet.hecoinfo.com/",
    apiKey: "2XTKM169DH3M36SIVIB28IM3433V37GGKX"
  },
  networks: {
    "ht-testnet": {
      url: "https://http-testnet.huobichain.com",
      accounts: ['b0acc12ed1ff644b0c0b5f823870ae032ea9d32a8ff7f0de5390787664adfeff']
    },
    "ht-testnet-user1": {
      url: "https://http-testnet.huobichain.com",
      accounts: ['fe713dc69ff3cd970ada3cf812701c943bac9daec8f730bad600ce4570cff627']
    },
    "ht-testnet-user2": {
      url: "https://http-testnet.huobichain.com",
      accounts: ['4a80ed77cc0d5dc214c5f358fd0fc49c0ed9926e178c170b0491f0770edbc530']
    },
    "ht-testnet-user3": {
      url: "https://http-testnet.huobichain.com",
      accounts: ['ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80']
    }
  }
};
