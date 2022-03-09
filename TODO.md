# TODO

### General + Reminders
- [ ] Create guide on how to run this project from tests to actual deployment (with config help)
- [ ] Have a landing page that will be built upon (3/19 Jacky's job)
- [ ] Have backend where we connect wallet, check balance, interact with contract button (i.e. getBalance) (3/19 Henry's job)
    - [ ] Connect wallet button
    - [ ] Check ETH balance
    - [ ] Interact with contract button (any function)
- [ ] Have a color scheme picked + some direction of what art we want like concepts + a name (3/26 Tommy's job, group is part of this too)
    - [ ] Color scheme selected
    - [ ] Name

### Contracts
- [ ] Have ERC721A work like a regular NFT (mint, transfer, burn, approval, etc)
    - [x] Mint
    - [x] Transfer
    - [x] Burn
    - [x] Approve
    - [ ] WIP!
- [ ] Create a ERC20 and have it work like a regular coin (transfer, burn, mint, approval, etc)
    - [ ] Mint
    - [ ] Transfer
    - [ ] Burn
    - [ ] Approve
    - [ ] WIP!
- [ ] Work on staking ERC721A to earn the ERC20 (AFTER BOTH ARE 100% WORKING WITH TESTS)

### Testing
- [x] Contract deployment (ownership and stuff)
- [x] Minting on different wallets
- [x] Transfer NFT between two wallets
- [x] Setting approval
- [ ] Withdraw funds
- [ ] Any interactions with contract that are not intended
    - [x] Minting with invalid amount of ETH sent
    - [ ] Non-owner fund withdrawal
    - [x] Minting while paused or sale off
    - [x] Non-owner flip sale state
    - [ ] WIP!
- [ ] WIP! (will add more as ERC721A development continues, as well as ERC20)

### Scripts
- [ ] Deploy the contract
- [ ] WIP! (will add more as more functions are made such as flip state or change sale config)