const hre = require("hardhat");

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

    // Set contract addresses to land, and edit GM's for $RESOURCE
    await warrior.connect(owner).setContractAddresses(land.address, resource.address);
    await resource.connect(owner).editGameMasters([warrior.address, land.address], [true, true]);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
    console.error(error);
    process.exit(1);
    });
