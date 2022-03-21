// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './Land.sol';
import './RESOURCE.sol';
import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Warrior is ERC721A, ERC721ABurnable, Ownable, ReentrancyGuard {

    uint16 public MAX_SUPPLY = 8888;
    uint64 public price = 0.08 ether;
    uint8 public maxPerWallet = 3;
    // uint32 public landClaimTime = 1 days;
    bool public saleLive;

    Land landContract;
    RESOURCE resource;
    
    uint8[4] public rankingsMaxLevel = [20, 40, 60, 80];

    // enum Actions { UNSTAKED, SCOUTING, FARMING, TRAINING }
    // struct Action  {
    //     address owner;
    //     uint64 timeStarted;
    //     uint8 action;
    // }

    struct WarriorStats {
        uint8 head;
        uint8 face;
        uint8 accessory;
        uint8 weapon;
        uint8 overall;
        uint8 background;
        uint8 trainingLVL;  // 255
        uint8 farmingLVL;   // 255
        uint16 trainingEXP; // 65000
        uint16 farmingEXP;  // 65000
        uint8 ranking;      // 255
    }

    // mapping (uint256 => bool) public landClaimed;
    // mapping (uint256 => Action) public activities;
    mapping (uint256 => WarriorStats) public stats;
    mapping (address => uint256) public numMinted;
    
    constructor() ERC721A("Warrior", "WARRIOR") {}
    
    /*
        ██████  ██    ██ ██████  ██      ██  ██████ 
        ██   ██ ██    ██ ██   ██ ██      ██ ██      
        ██████  ██    ██ ██████  ██      ██ ██      
        ██      ██    ██ ██   ██ ██      ██ ██      
        ██       ██████  ██████  ███████ ██  ██████ 
    */

    // if not staking land, just use any number
    // function changeActions(address _from, uint16[3] calldata _tokenIds, uint8[3] calldata _actions, uint16 _landTokenId) external {
    //     _changeActions(_from, _tokenIds, _actions, _landTokenId);
    // }

    function publicMint(uint256 amount, bool scout) external payable {
        require(this.totalSupply() + amount <= MAX_SUPPLY,           "Mint: Max supply reached!");
        require(tx.origin ==  msg.sender,                            "Mint: No contract mints!");
        if (msg.sender != owner()) {
            require(saleLive,                                        "Mint: Sale is not live!");
            require(0 < amount 
                    && amount+numMinted[msg.sender] <= maxPerWallet, "Mint: Invalid amount entered!");
            require(msg.value == price * amount,                     "Mint: Incorrect ETH amount!");
        }

        uint256 seed = _generateSeed();
        uint256 firstTokenId = _currentIndex;
        for (uint256 i; i < amount; i++) {
            _createWarrior(seed, firstTokenId+i);
            seed = _randomize(seed, firstTokenId+i);
        }
        numMinted[msg.sender] += amount;
        _safeMint(msg.sender, amount);

    
        // if (scout) {
        //     uint16[3] memory tokenIds;

        //     for (uint256 i; i < amount; i++)
        //         tokenIds[i] = uint16(_currentIndex + i);

        //     _safeMint(msg.sender, amount);
            
        //     _changeActions(msg.sender, tokenIds, [1, 1, 1], 0);
        // }
        // else {
            // _safeMint(msg.sender, amount);
        // }
    }

    // for now the levels are 0xp, 100xp, 200xp, 300xp, per level so y=100x (make a graph for visualizing when tryna find the right one)
    function addEXP(uint16[3] memory warriorTokenIds, uint8[3] memory actions, uint16[3] memory expArr) external {
        require(msg.sender == owner() || msg.sender == address(landContract), "EXP: Caller must be landContract contract");

        for (uint256 i; i < warriorTokenIds.length; i++) {
            WarriorStats memory warriorStats = stats[warriorTokenIds[i]];

            (warriorStats.farmingEXP, warriorStats.farmingLVL ) = 
                    _calculateEXPandLVL(actions[i], 
                        actions[i] == 2 ? warriorStats.farmingEXP : warriorStats.trainingEXP, 
                        actions[i] == 2 ? warriorStats.farmingLVL : warriorStats.trainingLVL,
                        expArr[i],
                        rankingsMaxLevel[warriorStats.ranking]);
        }
    }

    // function claimLandIfEligible(uint16[3] calldata _tokenIds) external {
    //     uint8 numEligible;
    //     for (uint256 i; i < _tokenIds.length; i++) {
    //         require(activities[_tokenIds[i]].owner == msg.sender, "Claim: Can't claim someone elses landContract!");
    //         require(!landClaimed[_tokenIds[i]], "Claim: landContract already claimed for tokenId!");

    //         // Must be staked for landClaimTime amount of timw
    //         if (block.timestamp > activities[_tokenIds[i]].timeStarted + landClaimTime) {
    //             numEligible++;
    //             landClaimed[_tokenIds[i]] = true;
    //         }
    //     }
    //     _changeActions(msg.sender, _tokenIds, [0, 0, 0], 0);
    //     landContract.mintLand(msg.sender, numEligible);
    // }

    /*
        ██ ███    ██ ████████ ███████ ██████  ███    ██  █████  ██      
        ██ ████   ██    ██    ██      ██   ██ ████   ██ ██   ██ ██      
        ██ ██ ██  ██    ██    █████   ██████  ██ ██  ██ ███████ ██      
        ██ ██  ██ ██    ██    ██      ██   ██ ██  ██ ██ ██   ██ ██      
        ██ ██   ████    ██    ███████ ██   ██ ██   ████ ██   ██ ███████ 
    */

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function _createWarrior(uint256 seed, uint256 tokenId) internal {
        seed = _randomize(seed, tokenId);

        // consider having 3 rarities for each trait, then pick a ranodm one from each rarity
        uint8 head = uint8((seed % 6)+1);       // 1-6
        uint8 face = uint8((seed % 6)+1);       // 1-6
        uint8 accessory = uint8((seed % 6)+1);  // 1-6
        uint8 weapon = uint8((seed % 6)+1);     // 1-6
        uint8 overall = uint8((seed % 6)+1);    // 1-6
        uint8 background = uint8((seed % 6)+1); // 1-6
        uint8 ranking = uint8((seed % 4));      // 0-3

        WarriorStats memory ws = WarriorStats(head, face, accessory, weapon, overall, background, 0, 0, 0, 0, ranking);
        stats[tokenId] = ws;
    }

    function _generateSeed() internal view returns (uint256) {
        return
            uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty)));
    }

    function _randomize(uint256 seed, uint256 tokenId) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(seed, tokenId)));
    }

    // function _changeActions(address _from, uint16[3] memory _warriorTokenIds, uint8[3] memory _actions, uint16 landTokenId) internal {
    //     bool stakeLand;
    //     for (uint256 i; i < _warriorTokenIds.length; i++) {
    //         require(ownerOf(_warriorTokenIds[i]) == _from || 
    //             activities[_warriorTokenIds[i]].owner == _from &&
    //             (msg.sender == address(landContract) || msg.sender == _from),
    //              "ChangeAction: Must be owner of token!");
    //         require(activities[_warriorTokenIds[i]].action != _actions[i], "ChangeAction: Already performing that action!");

    //         activities[_warriorTokenIds[i]] = Action({
    //             owner: _from,
    //             timeStarted: uint64(block.timestamp),
    //             action: _actions[i]
    //         });

    //         // check for security flaws
    //         // IF UNSTAKED
    //         if (_actions[i] == 0) {
    //             _approve(msg.sender, _warriorTokenIds[i], _from);
    //             _transfer(address(this), _from, _warriorTokenIds[i]);
    //         }
    //         // IF SCOUTING
    //         else if (_actions[i] == 1) {
    //             require(!landClaimed[_warriorTokenIds[i]], "ChangeAction: landContract already claimed for token!");
    //             _transfer(_from, address(this), _warriorTokenIds[i]);
    //         }
    //         else stakeLand = true;
    //     }

    //     if (stakeLand) {
    //         require(
    //             0 < _warriorTokenIds.length &&
    //             _warriorTokenIds.length <= 3 &&
    //             _warriorTokenIds.length == _actions.length,
    //             "ChangeAction: Invalid # of actions/warriors");
    //             for (uint256 i; i < _warriorTokenIds.length; i++) {
    //                 require(_from == ownerOf(_warriorTokenIds[i]) || _from == activities[_warriorTokenIds[i]].owner, "ChangeAction: Cant stake someone elses token!");
    //                 require(_actions[i] == 2 || _actions[i] == 3, "ChangeAction: Action(s) must be farming or training to stake to landContract");
    //             }
    //             landContract.stakeLand(_from, landTokenId, _warriorTokenIds, _actions);
    //             for (uint256 i; i < _warriorTokenIds.length; i++) {
    //                 _approve(msg.sender, _warriorTokenIds[i], _from);
    //                 _transfer(_from, address(this), _warriorTokenIds[i]);
    //             }
    //     }
    // }

    function _calculateEXPandLVL(uint8 _action, uint16 _exp, uint8 _lvl, uint16 _maxLVL, uint16 _expAdding) internal pure returns(uint16, uint8) {

        // *100 for farming, *200 for training
        uint8 multiplier = _action == 2 ? 100 : 200;

        uint16 newEXP = _exp+_expAdding;
        while (newEXP >= _lvl*multiplier && _lvl < _maxLVL) {
            newEXP -= _lvl*multiplier;
            _lvl++;
        }

        return (newEXP, _lvl);
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

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setContractAddresses(address _land, address _resource) external onlyOwner {
        landContract = Land(_land);
        resource = RESOURCE(_resource);
    }

    // function setLandClaimTime(uint32 _time) external onlyOwner {
    //     landClaimTime = _time;
    // }
}