# TODO

### General + Reminders
- [x] Create guide on how to run this project from tests to actual deployment (with config help)
- [ ] Have a landing page that will be built upon (3/19 Jacky's job)
- Have backend where we connect wallet, check balance, interact with contract button (i.e. getBalance) (3/19 Henry's job)
    - [ ] Connect wallet button
    - [ ] Check ETH balance
    - [ ] Interact with contract button (any function)
- Have a color scheme picked + some direction of what art we want like concepts + a name (3/26 Tommy's job, group is part of this too)
    - [ ] Color scheme selected
    - [ ] Name
    - [ ] Style of art

### Contracts
- ERC721A
    - [x] Mint, Transfer, Burn, Approve
    - [ ] Sale state variables and get/setters
    - [ ] Have metadata (just picture for now) be visible on opensea test network
    - [ ] Figure out trait randomization and apply it to minting process
- ERC20
    - [x] Mint, Transfer, Burn
- Staking contract
    - [ ] Be able to stake and claim

### Testing
- ERC721A
    - [x] Contract deployment (ownership and stuff)
    - [x] Minting on different wallets
    - [x] Transfer NFT between two wallets
    - [x] Setting approval
    - [x] Withdraw funds
    - [ ] WIP! Work on testing metadata stuff
    - Any interactions with contract that are not intended
        - [x] Minting with invalid amount of ETH sent
        - [x] Non-owner fund withdrawal
        - [x] Minting while paused or sale off
        - [x] Non-owner flip sale state
- ERC20
    - [ ] Have owner and GM mint/burn tokens
    - [ ] Non-owner/GM minting/burning ERC20 tokens
- Staking contract
    - [ ] Owner of tokenId stake and claim
    - [ ] Staking a tokenId not owned by msg.sender

### Scripts
- [ ] Deploy the contract