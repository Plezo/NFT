const { ethers } = require("hardhat");
const hre = require("hardhat");

async function main() {

    let warrior;
    let resource;
    let land;

    let owner;
    let addr1;
    let addr2;
    let addrs;

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
    console.log("Owner address:", owner.address);
    console.log("Addr1 address:", addr1.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
    console.error(error);
    process.exit(1);
    });
