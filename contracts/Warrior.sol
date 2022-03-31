// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import './Land.sol';
import './RESOURCE.sol';
import './Staking.sol';

contract Warrior is ERC721A, ERC721ABurnable, Ownable, ReentrancyGuard {

    uint16 public MAX_SUPPLY = 8888;
    uint64 public price = 0.08 ether;
    uint8 public maxPerWallet = 3;
    bool public saleLive;

    Land landContract;
    RESOURCE resource;
    Staking staking;

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
    }
    
    /*
        ██████  ██    ██ ██████  ██      ██  ██████ 
        ██   ██ ██    ██ ██   ██ ██      ██ ██      
        ██████  ██    ██ ██████  ██      ██ ██      
        ██      ██    ██ ██   ██ ██      ██ ██      
        ██       ██████  ██████  ███████ ██  ██████ 
    */

    // 175k gas limit for 3, try lowering
    function publicMint(uint256 amount) external payable {
        require(this.totalSupply() + amount <= MAX_SUPPLY,           "Mint: Max supply reached!");
        require(tx.origin ==  msg.sender,                            "Mint: No contract mints!");
        if (msg.sender != owner()) {
            require(saleLive,                                        "Mint: Sale is not live!");
            require(0 < amount 
                    && amount+numMinted[msg.sender] <= maxPerWallet, "Mint: Invalid amount entered!");
            require(msg.value == price * amount,                     "Mint: Incorrect ETH amount!");
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
        require(msg.sender == owner() || msg.sender == address(staking), 
            "EXP: Caller must be Staking contract");

        for (uint256 i; i < _warriorTokenIds.length; i++) {
            if (_warriorTokenIds[i] == 0) continue;

            WarriorStats memory warriorStats = stats[_warriorTokenIds[i]];

            (stats[_warriorTokenIds[i]].farmingEXP, stats[_warriorTokenIds[i]].farmingLVL ) = 
                    _calculateEXPandLVL(_actions[i], 
                        _actions[i] == 2 ? warriorStats.farmingEXP : warriorStats.trainingEXP, 
                        _actions[i] == 2 ? warriorStats.farmingLVL : warriorStats.trainingLVL,
                        rankingsMaxLevel[warriorStats.ranking],
                        _expArr[i]);
        }
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if ((_msgSender() != owner && _msgSender() != address(staking)) &&
            !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
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
        uint256 _action,
        uint256 _exp,
        uint256 _lvl,
        uint256 _maxLVL,
        uint256 _expAdding)
        internal pure returns(uint16, uint8) {

        // *100 for farming, *200 for training
        uint256 multiplier = _action == 2 ? 100 : 200;

        uint256 newEXP = _exp+_expAdding;
        while (newEXP >= _lvl*multiplier && _lvl < _maxLVL) {
            newEXP -= _lvl*multiplier;
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
        saleLive = !saleLive;
    }

    function changeBaseURI(string memory _baseuri) external onlyOwner {
        baseURI = _baseuri;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setContractAddresses(address _land, address _resource, address _staking) external onlyOwner {
        landContract = Land(_land);
        resource = RESOURCE(_resource);
        staking = Staking(_staking);
    }
}