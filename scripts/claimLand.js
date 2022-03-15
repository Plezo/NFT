const { ethers } = require("hardhat");
const hre = require("hardhat");

async function main() {

    const warriorAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
    const resourceAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
    const landAddress = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";

    const Warrior = await ethers.getContractFactory("Warrior");
    const warrior = await Warrior.attach(warriorAddress);

    const RESOURCE = await ethers.getContractFactory("RESOURCE");
    const resource = await RESOURCE.attach(resourceAddress);

    const Land = await ethers.getContractFactory("Land");
    const land = await Land.attach(landAddress);

    let owner;
    let addr1;
    let addr2;
    let addr3;
    [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();

    for (let i = 0; i < (await warrior.totalSupply()); i++)
    {
        console.log(i, (await warrior.ownerOf(i)));
    }

    await warrior.connect(addr1).claimLand(0, 0);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
    console.error(error);
    process.exit(1);
    });
