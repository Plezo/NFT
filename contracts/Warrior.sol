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
    uint8 public maxPerTx = 3;
    uint32 public landClaimTime = 1 days;
    bool public saleLive;

    Land landContract;
    RESOURCE resource;
    
    uint8[4] public rankingsMaxLevel = [20, 40, 60, 80];

    enum Actions { UNSTAKED, SCOUTING, FARMING, TRAINING }
    struct Action  {
        address owner;
        uint64 timeStarted;
        uint8 action;
    }

    struct WarriorStats {
        uint16 trainingLVL;
        uint16 farmingLVL;
        uint16 trainingEXP;
        uint16 farmingEXP;
        uint8 ranking;
    }

    mapping (uint256 => bool) public landClaimed;
    mapping (uint256 => Action) public activities;
    mapping (uint256 => WarriorStats) public stats;
    
    constructor() ERC721A("KingdomsNFT", "KNFT") {}
    
    /*
        ██████  ██    ██ ██████  ██      ██  ██████ 
        ██   ██ ██    ██ ██   ██ ██      ██ ██      
        ██████  ██    ██ ██████  ██      ██ ██      
        ██      ██    ██ ██   ██ ██      ██ ██      
        ██       ██████  ██████  ███████ ██  ██████ 
    */

    // if not staking land, just use any number
    function changeActions(address _from, uint16[3] calldata _tokenIds, uint8[3] calldata _actions, uint16 _landTokenId) external {
        _changeActions(_from, _tokenIds, _actions, _landTokenId);
    }

    // wip generate random rankings per
    function publicMint(uint256 amount, bool scout) external payable {
        require(saleLive, "Mint: Sale is not live!");
        require(tx.origin ==  msg.sender, "Mint: No contract mints!");
        require(this.totalSupply() + amount <= MAX_SUPPLY, "Mint: Max supply reached!");
        require(0 < amount && amount <= maxPerTx, "Mint: Invalid amount entered!");
        require(msg.value == price * amount, "Mint: Incorrect ETH amount!");
    
        if (scout) {
            uint16[3] memory tokenIds;

            for (uint256 i; i < amount; i++)
                tokenIds[i] = uint16(_currentIndex + i);

            _safeMint(msg.sender, amount);
            
            _changeActions(msg.sender, tokenIds, [1, 1, 1], 0);
        }
        else {
            _safeMint(msg.sender, amount);
        }
    }

    // for now the levels are 0xp, 100xp, 200xp, 300xp, per level so y=100x (make a graph for visualizing when tryna find the right one)
    function addEXP(uint16[3] memory warriorTokenIds, uint8[3] memory actions, uint16[3] memory expArr) external {
        require(msg.sender == owner() || msg.sender == address(landContract), "EXP: Caller must be landContract contract");

        for (uint256 i; i < warriorTokenIds.length; i++) {
            WarriorStats memory warriorStats = stats[warriorTokenIds[i]];

            (stats[warriorTokenIds[i]].farmingEXP, stats[warriorTokenIds[i]].farmingLVL ) = 
                    _calculateEXPandLVL(actions[i], 
                        actions[i] == 2 ? warriorStats.farmingEXP : warriorStats.trainingEXP, 
                        actions[i] == 2 ? warriorStats.farmingLVL : warriorStats.trainingLVL,
                        expArr[i],
                        rankingsMaxLevel[warriorStats.ranking]);

            // if (actions[i] == 2 && warriorStats.farmingLVL < rankingsMaxLevel[warriorStats.ranking])  {
            //     (stats[warriorStats.farmingEXP, warriorStats.farmingLVL ) = 
            //         _calculateEXPandLVL(Actions.FARMING, warriorStats.farmingEXP, warriorStats.farmingLVL, expArr[i]);
            // }
            // else if (actions[i] == 3 && stats[warriorTokenIds[i]].trainingLVL < rankingsMaxLevel[stats[warriorTokenIds[i]].ranking]) {
            //     (stats[warriorStats.trainingEXP, warriorStats.trainingLVL ) = 
            //         _calculateEXPandLVL(Actions.TRAINING, warriorStats.trainingEXP, warriorStats.trainingLVL, expArr[i]);
            // }
        }
    }

    function claimLandIfEligible(uint16[3] calldata _tokenIds) external {
        uint8 numEligible;
        for (uint256 i; i < _tokenIds.length; i++) {
            require(activities[_tokenIds[i]].owner == msg.sender, "Claim: Can't claim someone elses landContract!");
            require(!landClaimed[_tokenIds[i]], "Claim: landContract already claimed for tokenId!");

            // Must be staked for landClaimTime amount of timw
            if (block.timestamp > activities[_tokenIds[i]].timeStarted + landClaimTime) {
                numEligible++;
                landClaimed[_tokenIds[i]] = true;
            }
        }
        _changeActions(msg.sender, _tokenIds, [0, 0, 0], 0);
        landContract.mintLand(msg.sender, numEligible);
    }

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

    function _changeActions(address _from, uint16[3] memory _warriorTokenIds, uint8[3] memory _actions, uint16 landTokenId) internal {
        bool stakeLand;
        for (uint256 i; i < _warriorTokenIds.length; i++) {
            require(ownerOf(_warriorTokenIds[i]) == _from || 
                activities[_warriorTokenIds[i]].owner == _from &&
                (msg.sender == address(landContract) || msg.sender == _from),
                 "ChangeAction: Must be owner of token!");
            require(activities[_warriorTokenIds[i]].action != _actions[i], "ChangeAction: Already performing that action!");

            activities[_warriorTokenIds[i]] = Action({
                owner: _from,
                timeStarted: uint64(block.timestamp),
                action: _actions[i]
            });

            // check for security flaws
            // IF UNSTAKED
            if (_actions[i] == 0) {
                _approve(msg.sender, _warriorTokenIds[i], _from);
                _transfer(address(this), _from, _warriorTokenIds[i]);
            }
            // IF SCOUTING
            else if (_actions[i] == 1) {
                require(!landClaimed[_warriorTokenIds[i]], "ChangeAction: landContract already claimed for token!");
                _transfer(_from, address(this), _warriorTokenIds[i]);
            }
            else stakeLand = true;
        }

        if (stakeLand) {
            require(
                0 < _warriorTokenIds.length &&
                _warriorTokenIds.length <= 3 &&
                _warriorTokenIds.length == _actions.length,
                "ChangeAction: Invalid # of actions/warriors");
                for (uint256 i; i < _warriorTokenIds.length; i++) {
                    require(_from == ownerOf(_warriorTokenIds[i]) || _from == activities[_warriorTokenIds[i]].owner, "ChangeAction: Cant stake someone elses token!");
                    require(_actions[i] == 2 || _actions[i] == 3, "ChangeAction: Action(s) must be farming or training to stake to landContract");
                }
                landContract.stakeLand(_from, landTokenId, _warriorTokenIds, _actions);
                for (uint256 i; i < _warriorTokenIds.length; i++) {
                    _approve(msg.sender, _warriorTokenIds[i], _from);
                    _transfer(_from, address(this), _warriorTokenIds[i]);
                }
        }
    }

    function _calculateEXPandLVL(uint8 _action, uint16 _exp, uint16 _lvl, uint16 _maxLVL, uint16 _expAdding) internal pure returns(uint16, uint16) {

        // *100 for farming, *200 for training
        uint16 multiplier = _action == 2 ? 100 : 200;

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

    function ownerMint(bool scout) external onlyOwner {
        require(this.totalSupply() + 1 <= MAX_SUPPLY, "Mint: Max supply reached!");

        uint16[3] memory tokenIds; 
        tokenIds[0] = uint16(_currentIndex);
    
        if (scout) {
            _safeMint(msg.sender, 1);
            _changeActions(msg.sender, tokenIds, [1, 1, 1], 0);
        }
        else _safeMint(msg.sender, 1);
    }

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

    function setLandClaimTime(uint32 _time) external onlyOwner {
        landClaimTime = _time;
    }
}