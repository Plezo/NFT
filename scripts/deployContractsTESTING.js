const { ethers } = require("hardhat");

async function main() {

    let owner;
    [owner, ...addrs] = await ethers.getSigners();

    // Deploy Warrior
    const Warrior = await hre.ethers.getContractFactory("Warrior");
    const warrior = await Warrior.deploy();
    await warrior.deployed();
    console.log("Warrior deployed to:", warrior.address);

    // Deploy $RESOURCE
    const RESOURCE = await hre.ethers.getContractFactory("RESOURCE");
    const resource = await RESOURCE.deploy();
    await resource.deployed();
    console.log("Resource deployed to:", resource.address);

    // Deploy Land
    const Land = await hre.ethers.getContractFactory("Land");
    const land = await Land.deploy(warrior.address, resource.address);
    await land.deployed();
    console.log("Land deployed to:", land.address);

    // Enable sale
    await warrior.connect(owner).flipSaleState();

    // Set contract addresses to land, and edit GM's for $RESOURCE
    await warrior.connect(owner).setContractAddresses(land.address, resource.address);
    await resource.connect(owner).editGameMasters([warrior.address, land.address], [true, true]);

    // Set land claim to 0 seconds for testing purposes
    await warrior.connect(owner).setLandClaimTime(0);
    
    // Set game parameters for testing purposes
    await land.connect(owner).setVars(ethers.utils.parseEther("10"), ethers.utils.parseEther("1000000"), 120, 10, 1);

    // need to mint token id 0 due to issues with code (idk if I need to "fix")
    await warrior.connect(owner).ownerMint(false);
    await land.connect(owner).mintLand(owner.address, 1);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
    console.error(error);
    process.exit(1);
    });
