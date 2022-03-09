const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");

describe("KingdomsNFT", function () {
    let Token;
    let knft;
    let owner;
    let addr1;
    let addr2;
    let addrs;

    async function mint(token, signer, amount, price) {
        const mintingTx = await token.connect(signer).publicMint(amount, {value: ethers.utils.parseEther(`${price}`)});
        await mintingTx.wait();
    }

    // `beforeEach` will run before each test, re-deploying the contract every time
    beforeEach(async function () {
        Token = await ethers.getContractFactory("KingdomsNFT");
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
        knft = await Token.deploy();
        knft.connect(owner).flipSaleState();
    });

    describe("Deployment", function () {
        it("Should set the right owner", async function () {
            // This test expects the owner variable stored in the contract to be equal to our Signer's owner.
            expect(await knft.owner()).to.equal(owner.address);
        });

        it("Should assign the total supply of tokens to the owner", async function () {
            const ownerBalance = await knft.balanceOf(owner.address);
            expect(await knft.totalSupply()).to.equal(ownerBalance);
        });
    });

    describe("Interactions", function () {

        it("Should successfully mint for two non-owner addresses", async function () {
            const amount = 5;

            const initialSupply = await knft.totalSupply();

            const addr1Balance = await knft.balanceOf(addr1.address);
            await mint(knft, addr1, amount, 0.4);

            const addr2Balance = await knft.balanceOf(addr2.address);
            await mint(knft, addr2, amount, 0.4);

            expect(await knft.balanceOf(addr1.address)).to.equal(addr1Balance + amount);
            expect(await knft.balanceOf(addr2.address)).to.equal(addr2Balance + amount);
            expect(await knft.totalSupply()).to.equal(initialSupply + amount*2);
        });
        
        it("Should transfer tokens between accounts", async function () {
            const amount = 5;

            // Mints the tokens for the two addresses
            await mint(knft, addr1, amount, 0.4);
            await mint(knft, addr2, amount, 0.4);


            // Transfer 1 tokens from addr1 to addr2
            await knft.connect(addr1).transferFrom(addr1.address, addr2.address, 0);
            expect(await knft.balanceOf(addr1.address)).to.equal(amount - 1);
            expect(await knft.balanceOf(addr2.address)).to.equal(amount + 1);
            expect(await knft.ownerOf(0)).to.equal(addr2.address);
        
            // Transfer same token from addr2 to addr1
            await knft.connect(addr2).transferFrom(addr2.address, addr1.address, 0);
            expect(await knft.balanceOf(addr1.address)).to.equal(amount);
            expect(await knft.balanceOf(addr2.address)).to.equal(amount);
            expect(await knft.ownerOf(0)).to.equal(addr1.address);
        });

        it("Should be able to transfer another address or burn if approved", async function () {
            await mint(knft, addr1, 2, 0.16);

            // transfer should not work
            await expect(
                knft.connect(addr2).transferFrom(addr1.address, addr2.address, 0))
            .to.be.revertedWith("TransferCallerNotOwnerNorApproved()");

            // burn should not work either
            await expect(knft.connect(addr2).burn(1)).to.be.revertedWith("()");

            // approves addr2 transfer or burn addr1's nft's
            await knft.connect(addr1).setApprovalForAll(addr2.address, true);

            // transfer should work now
            await knft.connect(addr2).transferFrom(addr1.address, addr2.address, 0);
            expect(await knft.balanceOf(addr2.address)).to.equal(1);
            expect(await knft.ownerOf(0)).to.equal(addr2.address);

            // addr2 should be able to burn #1 after approval of addr1's nfts
            // total supply should drop after burn as well
            expect(await knft.totalSupply()).to.equal(2);
            await knft.connect(addr2).burn(1)
            expect(await knft.balanceOf(addr1.address)).to.equal(0);
            expect(await knft.totalSupply()).to.equal(1);
        })

        it("Should be able to burn selected tokenid", async function () {
            await mint(knft, addr1, 1, 0.08);
            expect(await knft.balanceOf(addr1.address)).to.equal(1);
            expect(await knft.totalSupply()).to.equal(1);

            await knft.connect(addr1).burn(0);
            expect(await knft.balanceOf(addr1.address)).to.equal(0);
            expect(await knft.totalSupply()).to.equal(0);
            await expect(knft.ownerOf(0)).to.be.revertedWith("OwnerQueryForNonexistentToken()");
        })
    });

    describe("Owner Interactions", function () {
        it("Should successfully withdraw ETH", async function () {
            knft.connect(owner).publicMint(10, {value: ethers.utils.parseEther("0.8")})
            expect(await waffle.provider.getBalance(knft.address)).to.equal(ethers.utils.parseEther("0.8"));

            knft.connect(owner).withdraw(ethers.utils.parseEther("0.2"))
            expect(await waffle.provider.getBalance(knft.address)).to.equal(ethers.utils.parseEther("0.6"));

            knft.connect(owner).withdraw(0)
            expect(await waffle.provider.getBalance(knft.address)).to.equal(ethers.utils.parseEther("0"));
        });

        it("Should successfully flip sale state", async function () {
            const prevFlipState = await knft.saleLive();

            await knft.connect(owner).flipSaleState();
            expect(await knft.saleLive()).to.equal(!prevFlipState);
        });
    })

    describe("Fails", function () {

        it("Should fail to mint if invalid ETH amount sent", async function () {
            await expect(
                knft.connect(addr1).publicMint(1, {value: ethers.utils.parseEther("0.01")})
            ).to.be.revertedWith("Incorrect ETH amount!");

            await expect(
                knft.connect(addr1).publicMint(1, {value: ethers.utils.parseEther("0.2")})
            ).to.be.revertedWith("Incorrect ETH amount!");
        })

        it("Should fail to transfer if addr2 tries transfering an nft they don't own", async function () {
            // Mints the tokens for addr1
            await mint(knft, addr1, 5, 0.4);

            const initialOwnerBalance = await knft.balanceOf(addr1.address);
        
            // Try to send 1 token from addr1 (5 tokens) to addr2 (0 tokens).
            await expect(
                knft.connect(addr2).transferFrom(addr1.address, addr2.address, 0)
            ).to.be.revertedWith("TransferCallerNotOwnerNorApproved()");
        
            // Owner balance shouldn't have changed.
            expect(await knft.balanceOf(addr1.address)).to.equal(initialOwnerBalance);
        })

        it("Should not allow non-owner to change sale variables or withdraw", async function () {
            // sets it back to false
            knft.connect(owner).flipSaleState();

            await expect(knft.connect(addr1).flipSaleState()).to.be.revertedWith("Ownable: caller is not the owner");
            await expect(knft.connect(addr1).withdraw(0)).to.be.revertedWith("Ownable: caller is not the owner");
        })

        it("Should not allow anyone to mint while sale is not live", async function () {
            // sets it back to false
            knft.connect(owner).flipSaleState();
            await expect(
                knft.connect(addr1).publicMint(1, {value: ethers.utils.parseEther("0.08")}))
            .to.be.revertedWith("Sale is not live!");
        })
    })
});
