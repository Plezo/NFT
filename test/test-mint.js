/* TODO
Eventually check for whitelist mint and see if it works, expect non whitelist to fail and whitelist to work
*/

const { expect } = require("chai");
const { ethers } = require("hardhat");

const amount = 5;
const price = "0.08";

describe("KingdomsNFT", function () {
    let Token;
    let knft;
    let owner;
    let addr1;
    let addr2;
    let addrs;

    async function mint(token, signer) {
        const mintingTx = await token.connect(signer).publicMint(amount, {value: ethers.utils.parseEther(price)});
        await mintingTx.wait();
    }

    // `beforeEach` will run before each test, re-deploying the contract every
    // time. It receives a callback, which can be async.
    beforeEach(async function () {
        Token = await ethers.getContractFactory("KingdomsNFT");
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
        knft = await Token.deploy();
    });

    describe("Deployment", function () {
        it("Should set the right owner", async function () {
            // This test expects the owner variable stored in the contract to be equal
            // to our Signer's owner.
            expect(await knft.owner()).to.equal(owner.address);
        });

        it("Should assign the total supply of tokens to the owner", async function () {
            const ownerBalance = await knft.balanceOf(owner.address);
            expect(await knft.totalSupply()).to.equal(ownerBalance);
        });
    });

    describe("Minting", function () {

        it("Should successfully mint for address 1", async function () {
            const addr1Balance = await knft.balanceOf(addr1.address);
            await mint(knft, addr1);
            expect(await knft.balanceOf(addr1.address)).to.equal(addr1Balance + amount);
        });

        it("Should successfully mint for address 2", async function () {
            const addr2Balance = await knft.balanceOf(addr1.address);
            await mint(knft, addr2);
            expect(await knft.balanceOf(addr2.address)).to.equal(addr2Balance + amount);
        });

        // WIP
        // it("Should successfully refund extra eth sent", async function () {
        //     expect(1 == 2);
        // })
        
        it("Should transfer tokens between accounts", async function () {
            await mint(knft, addr1);
            await mint(knft, addr2);


            // Transfer 1 tokens from addr1 to addr2
            await knft.connect(addr1).transferFrom(addr1.address, addr2.address, 0);
            expect(await knft.balanceOf(addr1.address)).to.equal(amount - 1);
            expect(await knft.balanceOf(addr2.address)).to.equal(amount + 1);
            expect(await knft.ownerOf(0)).to.equal(addr2.address);
        
            // Transfer same token from addr2 to addr1
            await knft.connect(addr2).transferFrom(addr2.address, addr1.address, 0);
            expect(await knft.balanceOf(addr1.address)).to.equal(amount + 1);
            expect(await knft.balanceOf(addr2.address)).to.equal(amount - 1);
            expect(await knft.ownerOf(0)).to.equal(addr1.address);
        });
    
        // it("Should fail if sender doesn’t have enough tokens", async function () {
        //     const initialOwnerBalance = await hardhatToken.balanceOf(owner.address);
        
        //     // Try to send 1 token from addr1 (0 tokens) to owner (1000000 tokens).
        //     // `require` will evaluate false and revert the transaction.
        //     await expect(
        //         hardhatToken.connect(addr1).transfer(owner.address, 1)
        //     ).to.be.revertedWith("Not enough tokens");
        
        //     // Owner balance shouldn't have changed.
        //     expect(await hardhatToken.balanceOf(owner.address)).to.equal(
        //         initialOwnerBalance
        //     );
        // });
    
        // it("Should update balances after transfers", async function () {
        //     const initialOwnerBalance = await hardhatToken.balanceOf(owner.address);
        
        //     // Transfer 100 tokens from owner to addr1.
        //     await hardhatToken.transfer(addr1.address, 100);
        
        //     // Transfer another 50 tokens from owner to addr2.
        //     await hardhatToken.transfer(addr2.address, 50);
        
        //     // Check balances.
        //     const finalOwnerBalance = await hardhatToken.balanceOf(owner.address);
        //     expect(finalOwnerBalance).to.equal(initialOwnerBalance.sub(150));
        
        //     const addr1Balance = await hardhatToken.balanceOf(addr1.address);
        //     expect(addr1Balance).to.equal(100);
        
        //     const addr2Balance = await hardhatToken.balanceOf(addr2.address);
        //     expect(addr2Balance).to.equal(50);
        // });
      });
});
