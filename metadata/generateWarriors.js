const { ethers } = require("hardhat");
const fs = require('fs');
const warriorsPath = './metadata/warriors';

const Weapons = [
    [...Array(35).keys()],  // Rank 1
    [...Array(30).keys()],  // Rank 2
    [...Array(24).keys()],  // Rank 3
    [...Array(12).keys()]   // Rank 4
]

// 0 -> n/2 is male n/2 -> n-1 is female
const Armor = [
    [...Array(50).keys()],  // Rank 1
    [...Array(44).keys()],  // Rank 2
    [...Array(36).keys()],  // Rank 3
    [...Array(16).keys()]   // Rank 4
]

// 0 -> n/2 is male n/2 -> n-1 is female
const Headpiece = [
    [...Array(50).keys()],  // Rank 1
    [...Array(44).keys()],  // Rank 2
    [...Array(36).keys()],  // Rank 3
    [...Array(16).keys()]   // Rank 4
]

// 0 -> n/2 is male n/2 -> n-1 is female
const Face = [
    [...Array(100).keys()], // Hair
    [...Array(40).keys()],  // Eyes
    [...Array(40).keys()]   // Mouth
]

// Accessories are really 1 less, 0 index is "No accessory"
const Accessories = [
    [...Array(16).keys()],  // Face
    [...Array(13).keys()],  // Body
    [...Array(9).keys()]    // TBD
]

const Background = [...Array(10).keys()];

// Min and max are inclusive
function randomInt(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

// Returns the next ungenerated tokenID
function nextOneToGenerate() {
    let next = fs.readdirSync(warriorsPath).length+1;
    if (next == 0) 
        next = 1;

    return next;
}

// Creates json file for given tokenID
function writeToJSON(JSONObj) {
    let JSONStr = JSON.stringify(JSONObj, null, '\t');
    fs.writeFileSync(`${warriorsPath}/${JSONObj['TokenID']}.json`, JSONStr, 'utf8');
}

// Generates metadata for each warrior
function generateWarrior(tokenId, ranking) {
    let gender = (randomInt(0, 1));

    let weapon = randomInt(0, Weapons[ranking-1].length-1);
    
    let armor = 
        gender == 0
        ? randomInt(0, (Armor[ranking-1].length/2)-1)
        : randomInt(Armor[ranking-1].length/2, Armor[ranking-1].length-1);

    let headpiece = 
        gender == 0
        ? randomInt(0, (Headpiece[ranking-1].length/2)-1)
        : randomInt(Headpiece[ranking-1].length/2, Headpiece[ranking-1].length-1);

    let hair =
        gender == 0
        ? randomInt(0, (Face[0].length/2)-1)
        : randomInt(Face[0].length/2, Face[0].length-1);

    let eyes =
        gender == 0
        ? randomInt(0, (Face[1].length/2)-1)
        : randomInt(Face[1].length/2, Face[1].length-1);

    let mouth =
        gender == 0
        ? randomInt(0, (Face[2].length/2)-1)
        : randomInt(Face[2].length/2, Face[2].length-1);

    let faceaccessory = 0;
    let bodyaccessory = 0;
    let tbdaccessory = 0;

    if ((randomInt(1,100)) > 50) {
        faceaccessory = randomInt(1, Accessories[0].length-1)
        if ((randomInt(1,100)) > 80) {
            bodyaccessory = randomInt(1, Accessories[1].length-1)
            if ((randomInt(1,100)) > 95) {
                tbdaccessory = randomInt(1, Accessories[2].length-1)
            }
        }
    }
    let background = randomInt(0, Background.length-1);

    let metadataJSONObj = {
        "uri": `/${tokenId}`,
        "TokenID": tokenId,
        "Collection": "NFT",
        "Attributes": [
            {
                "trait-type": "Ranking",
                "value": ranking
            },
            {
                "trait-type": "Gender",
                "value": gender == 0 ? "Male" : "Female"
            },
            {
                "trait-type": "Weapon",
                "value": weapon
            },
            {
                "trait-type": "Armor",
                "value": armor
            },
            {
                "trait-type": "Headpiece",
                "value": headpiece
            },
            {
                "trait-type": "Hair",
                "value": hair
            },
            {
                "trait-type": "Eyes",
                "value": eyes
            },
            {
                "trait-type": "Mouth",
                "value": mouth
            },
            {
                "trait-type": "FaceAccessory",
                "value": faceaccessory
            },
            {
                "trait-type": "BodyAccessory",
                "value": bodyaccessory
            },
            {
                "trait-type": "TBDAccessory",
                "value": tbdaccessory
            },
            {
                "trait-type": "Background",
                "value": background
            }
        ]
    }

    return metadataJSONObj;
}

// 50/50 for gender
// Fetch ranking from contract
// Weapon - Mouth all are determined by ranking
// Accessories -> 1: 50%, 2: 20%, 3: 5%
// Background some random color

async function main() {
    const warriorAddress = "0x8bCe54ff8aB45CB075b044AE117b8fD91F9351aB";

    const Warrior = await ethers.getContractFactory("Warrior");
    warrior = await Warrior.attach(warriorAddress);

    const nextGenerate = nextOneToGenerate();
    const numMinted = await warrior.totalSupply();

    for (let i = nextGenerate; i <= numMinted; i++) {
        const ranking = (await warrior.stats(i)).ranking;
        const metadataJSONObj = generateWarrior(i, ranking);

        writeToJSON(metadataJSONObj);
    }

    console.log(`Generated tokenIds ${nextGenerate} to ${numMinted}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
    console.error(error);
    process.exit(1);
    });

