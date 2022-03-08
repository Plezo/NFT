require("@nomiclabs/hardhat-waffle");

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
    mainnet: {
      url: process.env.MAINNET_RPC_URL,
      accounts: [`0x${privateKey}`]
    },
    ropsten: {
      url: process.env.ROPSTEN_RPC_URL,
      accounts: [`0x${privateKey}`]
    },
    rinkeby: {
      url: process.env.RINKEBY_RPC_URL,
      accounts: [`0x${privateKey}`]
    }
  }
};
