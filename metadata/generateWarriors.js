const { ethers } = require('hardhat');
const fs = require('fs');
const sharp = require('sharp')
const warriorJSON = './metadata/warriors/metadataJSON';

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
    let next = fs.readdirSync(warriorJSON).length+1;
    if (next == 0) 
        next = 1;

    return next;
}

// Creates json file for given tokenID
function writeToJSON(JSONObj) {
    let JSONStr = JSON.stringify(JSONObj, null, '\t');
    fs.writeFileSync(`${warriorJSON}/${JSONObj['TokenID']}.json`, JSONStr, 'utf8');
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
                "trait-type": "Background",
                "value": background
            },
            {
                "trait-type": "Gender",
                "value": gender == 0 ? "Male" : "Female"
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
                "trait-type": "Weapon",
                "value": weapon
            },
            {
                "trait-type": "Hair",
                "value": hair
            },
            {
                "trait-type": "Armor",
                "value": armor
            },
            {
                "trait-type": "BodyAccessory",
                "value": bodyaccessory
            },
            {
                "trait-type": "Headpiece",
                "value": headpiece
            },
            {
                "trait-type": "TBDAccessory",
                "value": tbdaccessory
            }
        ]
    }

    return metadataJSONObj;
}

// Generates art with respective metadata (consider moving to python)
async function generateArt(JSONObj) {
    const baseDir = "./metadata/warriors/traits"

    let ranking;
    let compositeArr = [];
    let bgImage = "";

    JSONObj['Attributes'].forEach((trait) => {
        if (trait['trait-type'] == "Ranking")
            ranking = trait['value'];

        /* ------------------------------- TESTING PURPOSES ONLY ------------------------------- */
        else if (trait['trait-type'] == "Background")
            bgImage = `${baseDir}/background/0.png`;
        else if (['armor', 'headpiece', 'weapon'].includes(trait['trait-type'].toLowerCase())) {
            compositeArr.push(
                {
                    input: `${baseDir}/${trait['trait-type'].toLowerCase()}/1/0.png`
                })
        }
        else {
            compositeArr.push(
                {
                    input: `${baseDir}/${trait['trait-type'].toLowerCase()}/0.png`
                })
        }
        /* ------------------------------------------------------------------------------------ */

        /* Uncomment below and remove above once we get the art */

        // else if (trait['trait-type'] == "Background")
        //     bgImage = `${baseDir}/${trait['value']}.png`;
        // else if (['Armor', 'Headpiece', 'Weapon'].includes(trait['trait-type'])) {
        //     compositeArr.push(
        //         {
        //             input: `${baseDir}/${trait['trait-type'].toLowerCase()}/${ranking}/${trait['value']}.png`
        //         })
        // }
        // else {
        //     compositeArr.push(
        //         {
        //             input: `${baseDir}/${trait['trait-type'].toLowerCase()}/${trait['value']}.png`
        //         })
        // }


    })

    await sharp(bgImage)
        .composite(compositeArr)
        .toFile(`./metadata/warriors/generatedWarriors/${JSONObj['TokenID']}.png`);
}

// 50/50 for gender
// Fetch ranking from contract
// Weapon - Mouth all are determined by ranking
// Accessories -> 1: 50%, 2: 20%, 3: 5%
// Background some random color

async function main() {
    const warriorAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

    const Warrior = await ethers.getContractFactory("Warrior");
    warrior = await Warrior.attach(warriorAddress);

    const nextGenerate = nextOneToGenerate();
    const numMinted = await warrior.totalSupply();

    for (let i = nextGenerate; i <= numMinted; i++) {
        const ranking = (await warrior.stats(i)).ranking;
        const metadataJSONObj = generateWarrior(i, ranking);

        writeToJSON(metadataJSONObj);
        await generateArt(metadataJSONObj);
    }

    console.log(`Generated tokenIds ${nextGenerate} to ${numMinted}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
    console.error(error);
    process.exit(1);
    });

