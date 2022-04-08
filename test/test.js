const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function at100Gwei(gasLimit) {
    return ethers.utils.formatEther(ethers.utils.parseUnits("100", "gwei").mul(gasLimit));
}

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

    async function scoutWarriors(warriors) {
        await staking.connect(addr1).changeActions(warriors[0], [1, 1, 1], 0);
        await staking.connect(addr2).changeActions(warriors[1], [1, 1, 1], 0);
    }

    async function claimLand(warriors) {
        await staking.connect(addr1).claimLand(warriors[0]);
        await staking.connect(addr2).claimLand(warriors[1]);
    }

    async function farmWarriors(warriors, land) {
        await staking.connect(addr1).changeActions(warriors[0], [2, 2, 2], land[0]);
        await staking.connect(addr2).changeActions(warriors[1], [2, 2, 2], land[1]);
    }

    async function claimFarming(warriors) {
        await staking.connect(addr1).claim(warriors[0]);
        await staking.connect(addr2).claim(warriors[1]);
    }

    async function printGasLimits(amount, warriors, land) {
        const gasLimitMint = (await warrior.connect(addr1).estimateGas.publicMint(amount, {value: ethers.utils.parseEther(`${price*amount}`)})).toNumber()
        console.log(`Mint ${amount}:`, gasLimitMint, "\tGas cost @ 100gwei:", at100Gwei(gasLimitMint));
        await mintWarriors(amount);

        const gasLimitScout = (await staking.connect(addr1).estimateGas.changeActions(warriors[0], [1, 1, 1], 0)).toNumber();
        console.log("Scouting:", gasLimitScout, "\tGas cost @ 100gwei:", at100Gwei(gasLimitScout));
        await scoutWarriors(warriors);

        const gasLimitClaimLand = (await staking.connect(addr1).estimateGas.claimLand(warriors[0])).toNumber();
        console.log("Claim Land:", gasLimitClaimLand, "\tGas cost @ 100gwei:", at100Gwei(gasLimitClaimLand));
        await claimLand(warriors);

        const gasLimitChangeActions = (await staking.connect(addr1).estimateGas.changeActions(warriors[0], [2, 2, 2], 1)).toNumber();
        console.log("Farming:", gasLimitChangeActions, "\tGas cost @ 100gwei:", at100Gwei(gasLimitChangeActions));
        await farmWarriors(warriors, land);

        await sleep(10000); // 10 seconds

        const gasLimitclaim = (await staking.connect(addr1).estimateGas.claim(warriors[0])).toNumber();
        console.log("Claim:", gasLimitclaim, "\tGas cost @ 100gwei:", at100Gwei(gasLimitclaim));
        await claimFarming(warriors);
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
    });

    describe("Game pipeline with 3 warriors", function () {
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
            await scoutWarriors([[1, 2, 3], [4, 5, 6]]);

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
            await claimLand([[1, 2, 3], [4, 5, 6]]);

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
            await scoutWarriors([[1, 2, 3], [4, 5, 6]]);
            await claimLand([[1, 2, 3], [4, 5, 6]]);

            await farmWarriors([[1, 2, 3], [4, 5, 6]], [1, 4]);

            await sleep(10000); // 10 seconds

            await claimFarming([[1, 2, 3], [4, 5, 6]]);

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
            await printGasLimits(amount, [[1, 2, 3], [4, 5, 6]], [1, 4]);
            console.log("# of resource:", 
                ethers.utils.formatEther(await resource.balanceOf(addr1.address)))

            console.log(await warrior.stats(1));
        })
    });

    describe("Game pipeline with 1 warrior", function () {
        it("Should mint only when eligible", async function () {
            await warrior.connect(owner).flipSaleState();
            await expect(
                warrior.connect(addr1).publicMint(1, 
                    {value: ethers.utils.parseEther(`${price}`)}
                )
            ).to.be.reverted;
            await warrior.connect(owner).flipSaleState();

            await mintWarriors(1);
            expect(await warrior.totalSupply()).to.equal(2);
            expect(await warrior.balanceOf(addr1.address)).to.equal(1);
            expect(await warrior.balanceOf(addr2.address)).to.equal(1);
        })

        it("Should make warriors scout and claim land", async function () {
            // Mints warriors
            await mintWarriors(1);

            // Stakes warriors for scouting
            await scoutWarriors([[1, 0, 0], [2, 0, 0]]);

            // All warriors should be in staking contract
            expect(await warrior.balanceOf(addr1.address)).to.equal(0);
            expect(await warrior.balanceOf(addr2.address)).to.equal(0);
            expect(await warrior.balanceOf(staking.address)).to.equal(2);

            // Attempts to claim land if time is not reached (should revert)
            // Changes land claim time to day to check if reverts
            await staking.connect(owner).setVars(ethers.utils.parseEther("10"), 120, 10, 1, 86400);
            await expect(staking.connect(addr1).claimLand([1, 0, 0])).to.be.reverted;
            await staking.connect(owner).setVars(ethers.utils.parseEther("10"), 120, 10, 1, 0);

            // Claims land
            await claimLand([[1, 0, 0], [2, 0, 0]]);

            // Land should be in addr1 and addr2 wallets
            expect(await land.totalSupply()).to.equal(2);
            expect(await land.balanceOf(addr1.address)).to.equal(1);
            expect(await land.balanceOf(addr2.address)).to.equal(1);

            // Should get warriors back
            expect(await warrior.balanceOf(addr1.address)).to.equal(1);
            expect(await warrior.balanceOf(addr2.address)).to.equal(1);

            // Check if landClaimed is updated properly
            expect(await staking.landClaimed(1) == true);
        })

        it("Should successfully make warriors farm and claim rewards", async function () {
            await mintWarriors(1);
            await scoutWarriors([[1, 0, 0], [2, 0, 0]]);
            await claimLand([[1, 0, 0], [2, 0, 0]]);

            await farmWarriors([[1, 0, 0], [2, 0, 0]], [1, 2]);

            await sleep(10000); // 10 seconds

            await claimFarming([[1, 0, 0], [2, 0, 0]]);

            // Balances should update correctly
            expect(await warrior.balanceOf(addr1.address)).to.equal(0);
            expect(await warrior.balanceOf(addr2.address)).to.equal(0);
            expect(await warrior.balanceOf(staking.address)).to.equal(2);
            expect(await land.balanceOf(addr1.address)).to.equal(0);
            expect(await land.balanceOf(addr2.address)).to.equal(0);
            expect(await land.balanceOf(staking.address)).to.equal(2);

            // Check if warriorAction is updated correctly
            expect(await staking.warriorAction(1).owner == addr1.address);
            expect(await staking.warriorAction(1).action == 2);
            expect(await staking.warriorAction(1).landTokenId == 1);

            // Check if landStake is updated correctly
            expect(await staking.landStake(addr1.address).landTokenId == 1);
            expect(await staking.landStake(addr1.address).warriorTokenIds == [1, 0, 0]);

            // Check if any resource is minted
            expect(await resource.balanceOf(addr1.address) >= 0);
        })

        it("Should perform entire game pipeline and output gas limits", async function () {
            await printGasLimits(1, [[1, 0, 0], [2, 0, 0]], [1, 2]);
            console.log("# of resource:", 
                ethers.utils.formatEther(await resource.balanceOf(addr1.address)))

            console.log(await warrior.stats(1));
        })
    });
});