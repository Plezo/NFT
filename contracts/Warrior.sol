// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "./ERC721ABurnable.sol";

contract Warrior is ERC721A, ERC721ABurnable, Ownable, ReentrancyGuard {

    struct CollectionVars {
        uint16 MAX_SUPPLY;
        uint64 price;
        uint8 maxPerWallet;
        bool saleLive;
        uint8 farmingEXPperLVL;
        uint8 trainingEXPperLVL;
    }

    CollectionVars collectionVars;

    string public baseURI = "";
    
    uint8[4] public rankingsMaxLevel = [20, 40, 60, 80];

    struct WarriorStats {
        uint8 ranking;
        uint8 trainingLVL;  // 255
        uint8 farmingLVL;   // 255
        uint16 trainingEXP; // 65000
        uint16 farmingEXP;  // 65000
    }

    mapping (uint256 => WarriorStats) public stats;
    mapping (address => uint256) public numMinted;
    
    constructor(string memory _baseuri) ERC721A("Warrior", "WARRIOR") {
        baseURI = _baseuri;

        collectionVars.MAX_SUPPLY = 8888;
        collectionVars.price = 0.08 ether;
        collectionVars.maxPerWallet = 3;
        collectionVars.saleLive = false;
        collectionVars.farmingEXPperLVL = 100;
        collectionVars.trainingEXPperLVL = 20;
    }
    
    /*
        ██████  ██    ██ ██████  ██      ██  ██████ 
        ██   ██ ██    ██ ██   ██ ██      ██ ██      
        ██████  ██    ██ ██████  ██      ██ ██      
        ██      ██    ██ ██   ██ ██      ██ ██      
        ██       ██████  ██████  ███████ ██  ██████ 
    */

    function publicMint(uint256 amount) external payable {
        require(this.totalSupply() + amount <= collectionVars.MAX_SUPPLY, "Mint: Max supply reached!");
        require(tx.origin ==  msg.sender, "Mint: No contract mints!");
        if (msg.sender != owner()) {
            require(collectionVars.saleLive, "Mint: Sale is not live!");
            require(0 < amount 
                    && amount+numMinted[msg.sender] <= collectionVars.maxPerWallet,
                     "Mint: Invalid amount entered!");
            require(msg.value == collectionVars.price * amount, "Mint: Incorrect ETH amount!");
        }

        uint256[3] memory tokenIds = [_currentIndex, 0, 0];
        for (uint256 i = 1; i < amount; i++) {
            tokenIds[i] = tokenIds[0]+1;
        }
        _generateRankings(tokenIds);
        numMinted[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function addEXP(
        uint256[3] memory _warriorTokenIds, 
        uint256[3] memory _actions, 
        uint256[3] memory _expArr) 
        external {
        require(msg.sender == owner() || _isGameContract(msg.sender), 
            "EXP: Caller must be Staking contract");

        for (uint256 i; i < _warriorTokenIds.length; i++) {
            if (_warriorTokenIds[i] == 0) continue;

            WarriorStats memory warriorStats = stats[_warriorTokenIds[i]];

            (stats[_warriorTokenIds[i]].farmingEXP, stats[_warriorTokenIds[i]].farmingLVL ) = 
                    _calculateEXPandLVL( 
                        _actions[i] == 2 ? warriorStats.farmingEXP : warriorStats.trainingEXP,
                        _actions[i] == 2 ? collectionVars.farmingEXPperLVL : collectionVars.trainingEXPperLVL,
                        _actions[i] == 2 ? warriorStats.farmingLVL : warriorStats.trainingLVL,
                        rankingsMaxLevel[warriorStats.ranking],
                        _expArr[i]);
        }
    }

    /*
        ██ ███    ██ ████████ ███████ ██████  ███    ██  █████  ██      
        ██ ████   ██    ██    ██      ██   ██ ████   ██ ██   ██ ██      
        ██ ██ ██  ██    ██    █████   ██████  ██ ██  ██ ███████ ██      
        ██ ██  ██ ██    ██    ██      ██   ██ ██  ██ ██ ██   ██ ██      
        ██ ██   ████    ██    ███████ ██   ██ ██   ████ ██   ██ ███████ 
    */

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _generateRandNum(uint256 tokenId) internal view returns(uint256) {
        uint256 seed = 
            uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty)));
        return(uint256(keccak256(abi.encode(seed, tokenId))));
    }

    function _generateRankings(uint256[3] memory tokenIds) internal {
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 ranking;
            uint256 randNum = _generateRandNum(tokenIds[i]);
            if (randNum % 100 == 0) ranking = 4;     // 1%
            else if (randNum % 10 == 0) ranking = 3; // 10%
            else if (randNum % 5 == 0) ranking = 2;  // 20%
            else ranking = 1;

            stats[tokenIds[i]] = WarriorStats(uint8(ranking), 0, 0, 0, 0);
        }
    }

    function _calculateEXPandLVL(
        uint256 _exp,
        uint256 _expPerLVL,
        uint256 _lvl,
        uint256 _maxLVL,
        uint256 _expAdding)
        internal pure returns(uint16, uint8) {

        uint256 newEXP = _exp+_expAdding;
        while (newEXP >= _lvl*_expPerLVL && _lvl < _maxLVL) {
            newEXP -= _lvl*_expPerLVL;
            _lvl++;
        }

        return (uint16(newEXP), uint8(_lvl));
    }

    /*
         ██████  ██     ██ ███    ██ ███████ ██████  
        ██    ██ ██     ██ ████   ██ ██      ██   ██ 
        ██    ██ ██  █  ██ ██ ██  ██ █████   ██████  
        ██    ██ ██ ███ ██ ██  ██ ██ ██      ██   ██ 
         ██████   ███ ███  ██   ████ ███████ ██   ██ 
    */

    function flipSaleState() external onlyOwner {
        collectionVars.saleLive = !collectionVars.saleLive;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function addGameContract(address _gameContract) external onlyOwner {
        _gameContracts.push(_gameContract);
    }

    function changeBaseURI(string memory _baseuri) external onlyOwner {
        baseURI = _baseuri;
    }
}