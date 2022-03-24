const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function at100Gwei(gasLimit) {
    return ethers.utils.formatEther(ethers.utils.parseUnits("100", "gwei").mul(gasLimit));
}

// dont forget to mint token #0 for owner

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
        warrior = await Warrior.deploy("");

        const RESOURCE = await ethers.getContractFactory("RESOURCE");
        resource = await RESOURCE.deploy();

        const Land = await ethers.getContractFactory("Land");
        land = await Land.deploy("", warrior.address, resource.address);

        const Staking = await ethers.getContractFactory("Staking");
        staking = await Staking.deploy(warrior.address, land.address, resource.address);

        await warrior.connect(owner).flipSaleState();
        await warrior.connect(owner).setContractAddresses(land.address, resource.address, staking.address);
        await staking.connect(owner).setLandClaimTime(0);
        await resource.connect(owner).editGameMasters([staking.address], [true]);
        // await land.connect(owner).setVars(ethers.utils.parseEther("10"), ethers.utils.parseEther("1000000"), 120, 10, 1);

        // need to mint 0 due to issues with code (idk if I need to "fix")
        await warrior.connect(owner).publicMint(1);
        await land.connect(owner).mintLand(owner.address, 1);
        await warrior.connect(owner).burn(0);
        await land.connect(owner).burn(0);
    });

    describe("Warrior Contract", function () {
        it("Should mint, stake (scouting) warrior(s) and claim land", async function () {
            // Mints and stakes warriors
            // owner minted warrior #0 and burned it
            // addr1 will own warrior # 1, 2, 3
            // addr2 will own warrior # 4, 5, 6

            const gasLimitMint = (await warrior.connect(addr1).estimateGas.publicMint(amount, {value: ethers.utils.parseEther(`${price*amount}`)})).toNumber()
            console.log(`Mint ${amount} gas limit:`, gasLimitMint, "\nGas cost @ 100gwei:", at100Gwei(gasLimitMint));
            await warrior.connect(addr1).publicMint(amount, {value: ethers.utils.parseEther(`${price*amount}`)});
            await warrior.connect(addr2).publicMint(amount, {value: ethers.utils.parseEther(`${price*amount}`)});

            expect(await warrior.totalSupply()).to.equal(amount*2);
            expect(await warrior.balanceOf(addr1.address)).to.equal(3);
            expect(await warrior.balanceOf(addr2.address)).to.equal(3);

            await sleep(1000); // 10 seconds

            // Stakes warriors for scouting and claims land
            // owner burnt land #0
            // addr1 will own land # 1, 2, 3
            // addr2 will own land # 4, 5, 6

            const gasLimitclaimLandIfEligible = (await staking.connect(addr1).estimateGas.claim([1, 2, 3])).toNumber();
            console.log("Claim Land gas limit:", gasLimitclaimLandIfEligible, "\nGas cost @ 100gwei:", at100Gwei(gasLimitclaimLandIfEligible));
            await staking.connect(addr1).changeActions([1, 2, 3], [1, 1, 1], 0);
            await staking.connect(addr2).changeActions([4, 5, 6], [1, 1, 1], 0);

            expect(await warrior.balanceOf(addr1.address)).to.equal(0);
            expect(await warrior.balanceOf(addr2.address)).to.equal(0);
            expect(await warrior.balanceOf(staking.address)).to.equal(6);

            const gasLimitClaim = (await staking.connect(addr1).estimateGas.claim([1, 2, 3])).toNumber();
            console.log("Claim Land gas limit:", gasLimitClaim, "\nGas cost @ 100gwei:", at100Gwei(gasLimitClaim));
            await staking.connect(addr1).claim([1, 2, 3]);
            await staking.connect(addr2).claim([4, 5, 6]);

            expect(await land.totalSupply()).to.equal(amount*2);
            expect(await land.balanceOf(addr1.address)).to.equal(amount);
            expect(await land.balanceOf(addr2.address)).to.equal(amount);
            expect(await warrior.balanceOf(staking.address)).to.equal(amount);
            expect(await warrior.balanceOf(staking.address)).to.equal(amount);

            // Stakes land and the three warriors
            // addr1 stakes all their tokens as FARMING
            const gasLimitChangeActions = (await warrior.connect(addr1).estimateGas.changeActions([1, 2, 3], [2, 2, 2], 1)).toNumber();
            console.log("Change action gas limit:", gasLimitChangeActions, "\nGas cost @ 100gwei:", at100Gwei(gasLimitChangeActions));
            await warrior.connect(addr1).changeActions([1, 2, 3], [2, 2, 2], 1);

            await sleep(1000);

            const gasLimitclaim = (await land.connect(addr1).estimateGas.claim([1, 2, 3])).toNumber();
            console.log("Claim gas limit:", gasLimitclaim, "\nGas cost @ 100gwei:", at100Gwei(gasLimitclaim));
            await land.connect(addr1).claim([1, 2, 3]);

            console.log("# of resource:", ethers.utils.formatEther(await resource.balanceOf(addr1.address)));
            console.log("Farming LVL:", (await warrior.stats(1))[2]);
            console.log("Farming EXP:", (await warrior.stats(1))[4]);
        });
    });
});