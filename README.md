# NFT DEV

When using this code use an empty wallet so you dont accidentally deploy to mainnet :)

# Guide
1. Have node.js installed: https://nodejs.org/en/
2. In the terminal, run ```npm i``` in the folder with package.json
3. Create a .env file and add PRIVATE_KEY, MAINNET_RPC_URL, RINKEBY_RPC_URL ... You can get all these values from metamask
4. To compile contracts in the contracts folder, run ```npx hardhat compile```
5. To run tests on the contracts, run ```npx hardhat test```
6. If you want to run the code on your own eth node, run ```npx hardhat node``` to start the node, you'll have to change the network you're working on in config.js and private key in env
7. If you want to run a script (this is how you will interact with the contract when deployed to mainnet or any network for that matter), run ```node scripts/name-of-script.js```

# Useful commands

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
npx hardhat run scripts/sample-script.js (--network <NETWORK such as localhost>)
npx hardhat help
```
