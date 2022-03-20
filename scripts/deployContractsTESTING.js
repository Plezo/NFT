const { ethers } = require("hardhat");

async function main() {

    let warrior;
    let resource;
    let land;

    let owner;
    [owner, ...addrs] = await ethers.getSigners();

    // Deploy Warrior
    const Warrior = await ethers.getContractFactory("Warrior");
    warrior = await Warrior.deploy();
    console.log("Warrior deployed to:", warrior.address);

    // Deploy $RESOURCE
    const RESOURCE = await ethers.getContractFactory("RESOURCE");
    resource = await RESOURCE.deploy();
    console.log("Resource deployed to:", resource.address);

    // Deploy Land
    const Land = await ethers.getContractFactory("Land");
    land = await Land.deploy(warrior.address, resource.address);
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
