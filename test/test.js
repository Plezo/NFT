const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function at100Gwei(gasLimit) {
    return ethers.utils.formatEther(ethers.utils.parseUnits("100", "gwei").mul(gasLimit));
}

// dont forget to mint token #0 for owner

describe("Warrior", function () {
    const price = 0.08;

    let Token;
    let nft;
    let owner;
    let addr1;
    let addr2;
    let addrs;

    // `beforeEach` will run before each test, re-deploying the contract every time
    beforeEach(async function () {
        Token = await ethers.getContractFactory("Warrior");
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
        nft = await Token.deploy();
        nft.connect(owner).flipSaleState();
    });

    describe("Deployment", function () {
        it("Should set the right owner", async function () {
            // This test expects the owner variable stored in the contract to be equal to our Signer's owner.
            expect(await nft.owner()).to.equal(owner.address);
        });
    });

    describe("Interactions", function () {
        it("Should successfully mint, transfer, approve, burn", async function () {
            const amount = 3;

            const initialSupply = await nft.totalSupply();

            const addr1Balance = await nft.balanceOf(addr1.address);
            await nft.connect(addr1).publicMint(amount, false, {value: ethers.utils.parseEther(`${price*amount}`)})

            const addr2Balance = await nft.balanceOf(addr2.address);
            await nft.connect(addr2).publicMint(amount, false, {value: ethers.utils.parseEther(`${price*amount}`)})

            expect(await nft.balanceOf(addr1.address)).to.equal(addr1Balance + amount);
            expect(await nft.balanceOf(addr2.address)).to.equal(addr2Balance + amount);
            expect(await nft.totalSupply()).to.equal(initialSupply + amount*2);

            // transfer 1 tokens from addr1 to addr2
            await nft.connect(addr1).transferFrom(addr1.address, addr2.address, 0);
            expect(await nft.balanceOf(addr1.address)).to.equal(amount - 1);
            expect(await nft.balanceOf(addr2.address)).to.equal(amount + 1);
            expect(await nft.ownerOf(0)).to.equal(addr2.address);
        
            // transfer same token from addr2 to addr1
            await nft.connect(addr2).transferFrom(addr2.address, addr1.address, 0);
            expect(await nft.balanceOf(addr1.address)).to.equal(amount);
            expect(await nft.balanceOf(addr2.address)).to.equal(amount);
            expect(await nft.ownerOf(0)).to.equal(addr1.address);

            // transfer should not work
            await expect(
                nft.connect(addr2).transferFrom(addr1.address, addr2.address, 0))
            .to.be.revertedWith("TransferCallerNotOwnerNorApproved()");

            // burn should not work either
            await expect(nft.connect(addr2).burn(0)).to.be.revertedWith("TransferCallerNotOwnerNorApproved()");

            // approves addr2 transfer or burn addr1's nft's
            await nft.connect(addr1).setApprovalForAll(addr2.address, true);

            // transfer should work now
            await nft.connect(addr2).transferFrom(addr1.address, addr2.address, 0);
            expect(await nft.balanceOf(addr2.address)).to.equal(amount+1);
            expect(await nft.ownerOf(0)).to.equal(addr2.address);

            // transfer back
            await nft.connect(addr2).transferFrom(addr2.address, addr1.address, 0);

            // addr2 should be able to burn #1 after approval of addr1's nfts
            // total supply should drop after burn as well
            expect(await nft.totalSupply()).to.equal(amount*2);
            await nft.connect(addr2).burn(5)
            expect(await nft.balanceOf(addr1.address)).to.equal(amount);
            expect(await nft.balanceOf(addr2.address)).to.equal(amount-1);
            expect(await nft.totalSupply()).to.equal((amount*2)-1);


            await nft.connect(addr1).burn(0);
            expect(await nft.balanceOf(addr1.address)).to.equal(amount-1);
            expect(await nft.totalSupply()).to.equal((amount*2)-2);
            await expect(nft.ownerOf(0)).to.be.revertedWith("OwnerQueryForNonexistentToken()");
        });

        it("Should successfully withdraw ETH (owner)", async function () {
            nft.connect(owner).withdraw()
            expect(await waffle.provider.getBalance(nft.address)).to.equal(ethers.utils.parseEther("0"));
        });

        it("Should successfully flip sale state (owner)", async function () {
            const prevFlipState = await nft.saleLive();

            await nft.connect(owner).flipSaleState();
            expect(await nft.saleLive()).to.equal(!prevFlipState);
        });

        it("Should fail to mint if invalid ETH amount sent", async function () {
            await expect(
                nft.connect(addr1).publicMint(1, false, {value: ethers.utils.parseEther("0.01")})
            ).to.be.revertedWith("Incorrect ETH amount!");

            await expect(
                nft.connect(addr1).publicMint(1, false, {value: ethers.utils.parseEther("0.2")})
            ).to.be.revertedWith("Incorrect ETH amount!");
        })

        it("Should fail to transfer if addr2 tries transfering an nft they don't own", async function () {
            // mints the tokens for addr1;
            await nft.connect(addr1).publicMint(3, false, {value: ethers.utils.parseEther("0.24")})

            const initialOwnerBalance = await nft.balanceOf(addr1.address);
        
            // try to send 1 token from addr1 (5 tokens) to addr2 (0 tokens).
            await expect(
                nft.connect(addr2).transferFrom(addr1.address, addr2.address, 0)
            ).to.be.revertedWith("TransferCallerNotOwnerNorApproved()");
        
            // owner balance shouldn't have changed.
            expect(await nft.balanceOf(addr1.address)).to.equal(initialOwnerBalance);
        })

        it("Should not allow non-owner to change sale variables or withdraw", async function () {
            // sets it back to false
            nft.connect(owner).flipSaleState();

            await expect(nft.connect(addr1).flipSaleState()).to.be.revertedWith("Ownable: caller is not the owner");
            await expect(nft.connect(addr1).withdraw()).to.be.revertedWith("Ownable: caller is not the owner");
        })

        it("Should not allow anyone to mint while sale is not live", async function () {
            // sets it back to false
            nft.connect(owner).flipSaleState();
            await expect(
                nft.connect(addr1).publicMint(1, false, {value: ethers.utils.parseEther(`${price}`)}))
            .to.be.revertedWith("Sale is not live!");
        })

    });
});

describe("Staking", function () {
    let price = 0.08;
    let amount = 3;

    let warrior;
    let resource;
    let land;

    let owner;
    let addr1;
    let addr2;
    let addrs;

    // `beforeEach` will run before each test, re-deploying the contract every time
    beforeEach(async function () {
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

        const Warrior = await ethers.getContractFactory("Warrior");
        warrior = await Warrior.deploy();

        const RESOURCE = await ethers.getContractFactory("RESOURCE");
        resource = await RESOURCE.deploy();

        const Land = await ethers.getContractFactory("Land");
        land = await Land.deploy(warrior.address, resource.address);

        await warrior.connect(owner).flipSaleState();
        await warrior.connect(owner).setContractAddresses(land.address, resource.address);
        await warrior.connect(owner).setLandClaimTime(0);
        await resource.connect(owner).editGameMasters([warrior.address, land.address], [true, true]);
        // await land.connect(owner).setVars(ethers.utils.parseEther("10"), ethers.utils.parseEther("1000000"), 10, 10, 6000);

        // need to mint 0 due to issues with code (idk if I need to "fix")
        await warrior.connect(owner).ownerMint(false);
        await land.connect(owner).mintLand(owner.address, 1);
    });

    describe("Warriors", function () {
        it("Should mint, stake (scouting) warrior(s) and claim land", async function () {
            // Mints and stakes warriors
            // owner owns warrior #0
            // addr1 will own warrior # 1, 2, 3
            // addr2 will own warrior # 4, 5, 6

            const gasLimitMint = (await warrior.connect(addr1).estimateGas.publicMint(amount, true, {value: ethers.utils.parseEther(`${price*amount}`)})).toNumber()
            console.log(`Mint ${amount} gas limit:`, gasLimitMint, "\nGas cost @ 100gwei:", at100Gwei(gasLimitMint));
            await warrior.connect(addr1).publicMint(amount, true, {value: ethers.utils.parseEther(`${price*amount}`)});
            await warrior.connect(addr2).publicMint(amount, true, {value: ethers.utils.parseEther(`${price*amount}`)});

            expect(await warrior.totalSupply()).to.equal(amount*2+1);
            expect(await warrior.balanceOf(addr1.address)).to.equal(0);
            expect(await warrior.balanceOf(addr2.address)).to.equal(0);
            expect(await warrior.balanceOf(warrior.address)).to.equal(amount*2);
            expect((await warrior.activities(1))[0]).to.equal(addr1.address);
            expect((await warrior.activities(amount+1))[0]).to.equal(addr2.address);

            await sleep(1000); // 10 seconds

            // Claims land and unstakes warriors
            // owner owns land #0
            // addr1 will own land # 1, 2, 3
            // addr2 will own land # 4, 5, 6

            const gasLimitclaimLandIfEligible = (await warrior.connect(addr1).estimateGas.claimLandIfEligible([1, 2, 3])).toNumber();
            console.log("Claim Land gas limit:", gasLimitclaimLandIfEligible, "\nGas cost @ 100gwei:", at100Gwei(gasLimitclaimLandIfEligible));
            await warrior.connect(addr1).claimLandIfEligible([1, 2, 3]);
            await warrior.connect(addr2).claimLandIfEligible([4, 5, 6]);

            expect(await land.totalSupply()).to.equal(amount*2+1);
            expect(await land.balanceOf(addr1.address)).to.equal(amount);
            expect(await land.balanceOf(addr2.address)).to.equal(amount);
            expect(await warrior.balanceOf(addr1.address)).to.equal(amount);
            expect(await warrior.balanceOf(addr2.address)).to.equal(amount);

            // Stakes land and the three warriors
            // addr1 stakes all their tokens as FARMING
            const gasLimitChangeActions = (await warrior.connect(addr1).estimateGas.changeActions(addr1.address, [1, 2, 3], [2, 2, 2], 1)).toNumber();
            console.log("Claim Land gas limit:", gasLimitChangeActions, "\nGas cost @ 100gwei:", at100Gwei(gasLimitChangeActions));
            await warrior.connect(addr1).changeActions(addr1.address, [1, 2, 3], [2, 2, 2], 1);
            await sleep(1000);

            const gasLimitclaim = (await land.connect(addr1).estimateGas.claim(addr1.address, 1, true)).toNumber();
            console.log("Claim Land gas limit:", gasLimitclaim, "\nGas cost @ 100gwei:", at100Gwei(gasLimitclaim));
            await land.connect(addr1).claim(addr1.address, 1, true);

            console.log("# of resource:", await resource.balanceOf(addr1.address));
            console.log("Farming LVL:", (await warrior.stats(1))[1]);
            console.log("Farming EXP:", (await warrior.stats(1))[3]);
        });
    });
});