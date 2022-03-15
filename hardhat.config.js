require("@nomiclabs/hardhat-waffle");
require('dotenv').config()

const privateKey = process.env.PRIVATE_KEY;

module.exports = {

  solidity: { 
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 10000
      }
    }
  },
  networks: {
    // just in case :)
    // mainnet: {
    //   url: process.env.MAINNET_RPC_URL,
    //   accounts: [privateKey]
    // },
    ropsten: {
      url: process.env.ROPSTEN_RPC_URL,
      accounts: [privateKey]
    },
    rinkeby: {
      url: process.env.RINKEBY_RPC_URL,
      accounts: [privateKey]
    }
  }
};
