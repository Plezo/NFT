# KingdomsNFT DEV

When using this code use an empty wallet so: 1. we stay anonymous and 2. you dont accidentally deploy to mainnet

# Guide
WIP!

# TODO

### General (reminders included)
- [ ] Create guide on how to run this project from tests to actual deployment (with config help)
- [ ] Have a landing page that will be built upon (3/19 Jacky's job)
- [ ] Have backend where we connect wallet, check balance, interact with contract button (i.e. getBalance) (3/19 Henry's job)

### Contracts
- [ ] Have ERC721A work like a regular NFT (transfer, burn, approval, etc)
- [ ] Create a ERC20 and have it work like a regular coin (transfer, burn, mint, approval, etc)
- [ ] Work on staking ERC721A to earn the ERC20 (AFTER BOTH ARE 100% WORKING WITH TESTS)

### Testing
- [ ] Write test for setting approval (make a mimic opensea contract, or use the real one's code)
- [ ] Write test for any interactions with contract that are not intended (i.e. non owner withdrawal or mint while paused)
- [ ] Write test testing to see if refund works on mint
- [ ] WIP! (will add more as ERC721A development continues, as well as ERC20)

### Scripts
- [ ] Create script that will deploy the contract
- [ ] WIP! (will add more as more functions are made such as flip state or change sale config)

# Useful commands

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/sample-script.js
npx hardhat help
```