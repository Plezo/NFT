const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function at100Gwei(gasLimit) {
    return ethers.utils.formatEther(ethers.utils.parseUnits("100", "gwei").mul(gasLimit));
}

// dont forget to mint token #0 for owner

describe("Game pipeline", function () {
    let price = 0.08;
    let amount = 3;

    let warrior;
    let resource;
    let land;

    let owner;
    let addr1;
    let addr2;
    let addrs;

    async function mintWarriors(amountWarriors) {
        await warrior.connect(addr1).publicMint(amountWarriors, 
            {value: ethers.utils.parseEther(`${price*amountWarriors}`)});
        await warrior.connect(addr2).publicMint(amountWarriors, 
            {value: ethers.utils.parseEther(`${price*amountWarriors}`)});
    }

    async function scoutWarriors() {
        await staking.connect(addr1).changeActions([1, 2, 3], [1, 1, 1], 0);
        await staking.connect(addr2).changeActions([4, 5, 6], [1, 1, 1], 0);
    }

    async function claimLand() {
        await staking.connect(addr1).claimLand([1, 2, 3]);
        await staking.connect(addr2).claimLand([4, 5, 6]);
    }

    async function farmWarriors() {
        await staking.connect(addr1).changeActions([1, 2, 3], [2, 2, 2], 1);
        await staking.connect(addr2).changeActions([4, 5, 6], [2, 2, 2], 4);
    }

    async function claimFarming() {
        await staking.connect(addr1).claim([1, 2, 3]);
        await staking.connect(addr2).claim([4, 5, 6]);
    }

    async function printGasLimits() {
        const gasLimitMint = (await warrior.connect(addr1).estimateGas.publicMint(amount, {value: ethers.utils.parseEther(`${price*amount}`)})).toNumber()
        console.log(`Mint ${amount} gas limit:`, gasLimitMint, "\nGas cost @ 100gwei:", at100Gwei(gasLimitMint));
        await mintWarriors(amount);

        const gasLimitScout = (await staking.connect(addr1).estimateGas.changeActions([1, 2, 3], [1, 1, 1], 0)).toNumber();
        console.log("Change action scouting gas limit:", gasLimitScout, "\nGas cost @ 100gwei:", at100Gwei(gasLimitScout));
        await scoutWarriors();

        const gasLimitClaimLand = (await staking.connect(addr1).estimateGas.claimLand([1, 2, 3])).toNumber();
        console.log("Claim Land gas limit:", gasLimitClaimLand, "\nGas cost @ 100gwei:", at100Gwei(gasLimitClaimLand));
        await claimLand();

        const gasLimitChangeActions = (await staking.connect(addr1).estimateGas.changeActions([1, 2, 3], [2, 2, 2], 1)).toNumber();
        console.log("Change action farming gas limit:", gasLimitChangeActions, "\nGas cost @ 100gwei:", at100Gwei(gasLimitChangeActions));
        await farmWarriors();

        await sleep(10000); // 10 seconds

        const gasLimitclaim = (await staking.connect(addr1).estimateGas.claim([1, 2, 3])).toNumber();
        console.log("Claim gas limit:", gasLimitclaim, "\nGas cost @ 100gwei:", at100Gwei(gasLimitclaim));
        await claimFarming();
    }

    // `beforeEach` will run before each test, re-deploying the contracts every time
    beforeEach(async function () {
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

        const Warrior = await ethers.getContractFactory("Warrior");
        warrior = await Warrior.deploy("");

        const RESOURCE = await ethers.getContractFactory("RESOURCE");
        resource = await RESOURCE.deploy();

        const Land = await ethers.getContractFactory("Land");
        land = await Land.deploy("");


        const Staking = await ethers.getContractFactory("Staking");
        staking = await Staking.deploy(warrior.address, land.address, resource.address);

        await warrior.connect(owner).addGameContract(staking.address);
        await land.connect(owner).addGameContract(staking.address);

        // Flips sale state to true (TESTING PURPOSES ONLY!)
        await warrior.connect(owner).flipSaleState();
        
        /*
        BASE_RESOURCE_RATE:         10 ether,
        BASE_FARMING_EXP:           120,
        BASE_TRAINING_EXP:          10,
        BASE_TIME:                  1 seconds, (1 days = 86400)
        LAND_CLAIM_TIME:            0 seconds
        */
        // Changes vars to easier ones (TESTING PURPOSES ONLY!)
        await staking.connect(owner).setVars(ethers.utils.parseEther("10"), 120, 10, 1, 0);
        await resource.connect(owner).editGameMasters([staking.address], [true]);

        // need to mint 0 due to issues with code (idk if I need to "fix")
        await warrior.connect(owner).publicMint(1);
        await land.connect(owner).mintLand(owner.address, 1);
        await warrior.connect(owner).burn(0);
        await land.connect(owner).burn(0);

        console.log("Staking address:", staking.address);
        console.log("Addr1 address:", addr1.address);
    });

    describe("Game pipeline", function () {
        it("Should mint only when eligible", async function () {
            await warrior.connect(owner).flipSaleState();
            await expect(
                warrior.connect(addr1).publicMint(amount, 
                    {value: ethers.utils.parseEther(`${price*amount}`)}
                )
            ).to.be.reverted;
            await warrior.connect(owner).flipSaleState();

            await mintWarriors(amount);
            expect(await warrior.totalSupply()).to.equal(amount*2);
            expect(await warrior.balanceOf(addr1.address)).to.equal(amount);
            expect(await warrior.balanceOf(addr2.address)).to.equal(amount);
        })

        it("Should make warriors scout and claim land", async function () {
            // Mints warriors
            await mintWarriors(amount);

            // Stakes warriors for scouting
            await scoutWarriors();

            // All warriors should be in staking contract
            expect(await warrior.balanceOf(addr1.address)).to.equal(0);
            expect(await warrior.balanceOf(addr2.address)).to.equal(0);
            expect(await warrior.balanceOf(staking.address)).to.equal(amount*2);

            // Attempts to claim land if time is not reached (should revert)
            // Changes land claim time to day to check if reverts
            await staking.connect(owner).setVars(ethers.utils.parseEther("10"), 120, 10, 1, 86400);
            await expect(staking.connect(addr1).claimLand([1, 2, 3])).to.be.reverted;
            await staking.connect(owner).setVars(ethers.utils.parseEther("10"), 120, 10, 1, 0);

            // Claims land
            await claimLand();

            // Land should be in addr1 and addr2 wallets
            expect(await land.totalSupply()).to.equal(amount*2);
            expect(await land.balanceOf(addr1.address)).to.equal(amount);
            expect(await land.balanceOf(addr2.address)).to.equal(amount);

            // Should get warriors back
            expect(await warrior.balanceOf(addr1.address)).to.equal(amount);
            expect(await warrior.balanceOf(addr2.address)).to.equal(amount);

            // Check if landClaimed is updated properly
            expect(await staking.landClaimed(1) == true);
        })

        it("Should successfully make warriors farm and claim rewards", async function () {
            await mintWarriors(amount);
            await scoutWarriors();
            await claimLand();

            await farmWarriors();

            await sleep(10000); // 10 seconds

            await claimFarming();

            // Balances should update correctly
            expect(await warrior.balanceOf(addr1.address)).to.equal(0);
            expect(await warrior.balanceOf(addr2.address)).to.equal(0);
            expect(await warrior.balanceOf(staking.address)).to.equal(amount*2);
            expect(await land.balanceOf(addr1.address)).to.equal(amount-1);
            expect(await land.balanceOf(addr2.address)).to.equal(amount-1);
            expect(await land.balanceOf(staking.address)).to.equal(2);

            // Check if warriorAction is updated correctly
            expect(await staking.warriorAction(1).owner == addr1.address);
            expect(await staking.warriorAction(1).action == 2);
            expect(await staking.warriorAction(1).landTokenId == 1);

            // Check if landStake is updated correctly
            expect(await staking.landStake(addr1.address).landTokenId == 1);
            expect(await staking.landStake(addr1.address).warriorTokenIds == [1, 2, 3]);

            // Check if any resource is minted
            expect(await resource.balanceOf(addr1.address) >= 0);
        })

        it("Should perform entire game pipeline and output gas limits", async function () {
            await printGasLimits();
            console.log("# of resource:", 
                ethers.utils.formatEther(await resource.balanceOf(addr1.address)))

            console.log(await warrior.stats(1));
        })
    });
});