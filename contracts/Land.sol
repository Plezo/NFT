// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './Warrior.sol';
import './RESOURCE.sol';
import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import '@openzeppelin/contracts/security/Pausable.sol';

contract Land is ERC721A, ERC721ABurnable, Pausable, Ownable, ReentrancyGuard {

    // uint64 public BASE_RESOURCE_RATE = 10 ether;
    // uint128 public MAX_RESOURCE_CIRCULATING = 1000000 ether;
    // uint16 public BASE_FARMING_EXP = 10;
    // uint16 public BASE_TRAINING_EXP = 10;
    // uint32 public BASE_TIME = 1 days;

    Warrior warrior;
    RESOURCE resource;

    string public baseURI = "";

    // enum   Actions { UNSTAKED, SCOUTING, FARMING, TRAINING }

    struct LandStats {
        uint8 farmingMultiplier;
        uint8 trainingMultiplier;
    }

    // struct Stake {
    //     uint16 landTokenId;
    //     uint32 timeStaked;
    //     uint16[3] warriorTokenIds;
    //     uint8[3] actions;
    // }

    mapping(uint256 => LandStats) public stats;
    // mapping(address => Stake) public land;

    event TokenStaked(address owner, uint16 landTokenId, uint32 timeStaked, uint16[3] warriorTokenIds, uint8[3] _actions);

    constructor(string memory _baseuri, address _warrior, address _resource) ERC721A("Land", "LAND") { 
        baseURI = _baseuri;
        warrior = Warrior(_warrior);
        resource = RESOURCE(_resource);
    }

    /*
        ██████  ██    ██ ██████  ██      ██  ██████ 
        ██   ██ ██    ██ ██   ██ ██      ██ ██      
        ██████  ██    ██ ██████  ██      ██ ██      
        ██      ██    ██ ██   ██ ██      ██ ██      
        ██       ██████  ██████  ███████ ██  ██████ 
    */

    // function stakeLand(
    //     address _from,
    //     uint16 _landTokenId, 
    //     uint16[3] calldata _warriorTokenIds, 
    //     uint8[3] calldata _actions) 
    //     external whenNotPaused {
    //         require(msg.sender == address(warrior) || msg.sender == owner(), "StakeLand: Caller must be contract!");
    //         require(land[_from].timeStaked == 0, "StakeLand: Already have landContract staked!");

    //         _stakeLand(msg.sender, _from, _landTokenId, _warriorTokenIds, _actions);
    //     }

    // function claim(address _from, uint16 _landTokenId, bool unstakeLand) external whenNotPaused {
    //     require(land[_from].landTokenId == _landTokenId, "Claim: Can't claim for someone else!");
    //     require(land[_from].timeStaked != 0, "Claim: Not staked!");

    //     _claim(_from);

    //     if (unstakeLand) _unstakeLand(msg.sender, _landTokenId);
    // }

    /*
        ██ ███    ██ ████████ ███████ ██████  ███    ██  █████  ██      
        ██ ████   ██    ██    ██      ██   ██ ████   ██ ██   ██ ██      
        ██ ██ ██  ██    ██    █████   ██████  ██ ██  ██ ███████ ██      
        ██ ██  ██ ██    ██    ██      ██   ██ ██  ██ ██ ██   ██ ██      
        ██ ██   ████    ██    ███████ ██   ██ ██   ████ ██   ██ ███████ 
    */

    // function _stakeLand(
    //     address _from, 
    //     address _owner, 
    //     uint16 _landTokenId, 
    //     uint16[3] memory _warriorTokenIds, 
    //     uint8[3] memory _actions) 
    //     internal {
    //         land[_owner] = Stake({
    //             landTokenId: _landTokenId,
    //             timeStaked: uint32(block.timestamp),
    //             warriorTokenIds: _warriorTokenIds,
    //             actions: _actions
    //         });

    //         _approve(_from, _landTokenId, _owner);
    //         _transfer(_owner, address(this), _landTokenId);

    //         emit TokenStaked(_owner, _landTokenId, uint32(block.timestamp), _warriorTokenIds, _actions);
    // }

    // double check for security flaw (check if after transfer, transfer to someone else and try taking it back)
    // function _unstakeLand(address _from, uint16 _landTokenId) internal {
    //     _approve(_from, _landTokenId, _from);
    //     _transfer(address(this), _from, _landTokenId);

    //     // unstakes warriors too
    //     warrior.changeActions(_from, land[_from].warriorTokenIds, [0, 0, 0], _landTokenId);

    //     delete land[_from];
    // }

    // function _claim(address _from) internal {

    //     uint16[3] memory expArr;
    //     uint8[3] memory actionToUint;
    //     uint256 claimAmount;
    //     uint8 numFarming;

    //     for (uint256 i; i < land[_from].warriorTokenIds.length; i++) {
    //         if (land[_from].actions[i] == 2) {
    //             // 2 is FARMING
    //             actionToUint[i] = 2;
    //             // idk how rewards and exp will be calculated
    //             claimAmount += 
    //                 ((block.timestamp - land[_from].timeStaked)
    //                 * BASE_RESOURCE_RATE)
    //                 / BASE_TIME;

    //             // more you stake for farming, less you generate by 20% per
    //             claimAmount -= (claimAmount * numFarming)/5;

    //             expArr[i] = uint16(((block.timestamp - land[_from].timeStaked)
    //             * (BASE_FARMING_EXP / BASE_TIME) 
    //             * stats[land[_from].landTokenId].farmingMultiplierNumerator)
    //             / stats[land[_from].landTokenId].farmingMultiplierDenominator);
    //             numFarming++;
    //         }

    //         else if (land[_from].actions[i] == 3) {
    //             // 3 is TRAINING
    //             actionToUint[i] = 3;
    //             // idk how exp will be calculated
    //             expArr[i] = uint16(((
    //                 block.timestamp - land[_from].timeStaked)
    //                 * (BASE_TRAINING_EXP / BASE_TIME))
    //                 * stats[land[_from].landTokenId].trainingMultiplierNumerator)
    //                 / stats[land[_from].landTokenId].trainingMultiplierDenominator;
    //         }
    //     }
    //     if (claimAmount > 0 && resource.totalSupply() + claimAmount <= MAX_RESOURCE_CIRCULATING)
    //         resource.mint(_from, claimAmount);

    //     warrior.addEXP(land[_from].warriorTokenIds, actionToUint, expArr);     
    // }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /*
         ██████  ██     ██ ███    ██ ███████ ██████  
        ██    ██ ██     ██ ████   ██ ██      ██   ██ 
        ██    ██ ██  █  ██ ██ ██  ██ █████   ██████  
        ██    ██ ██ ███ ██ ██  ██ ██ ██      ██   ██ 
         ██████   ███ ███  ██   ████ ███████ ██   ██ 
    */

    function mintLand(address _to, uint256 _amount) external {
        require(totalSupply() + _amount <= warrior.MAX_SUPPLY(), "Exceeds supply!");

        // consider importing Accessible from openzepp instead
        require(msg.sender == owner() || msg.sender == address(warrior), "Not owner!");

        uint256 firstTokenId = _currentIndex;
        for (uint256 i; i < _amount; i++)
            _generateMultipliers(firstTokenId+i);

        _safeMint(_to, _amount);
    }

    function _generateRandNum(uint256 tokenId) internal view returns(uint256) {
        uint256 seed = 
            uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty)));
        return(uint256(keccak256(abi.encode(seed, tokenId))));
    }

    // consider support passing in an array of tokenids for gas efficiency
    // consider adding weights to intervals (i.e. 10% to have >800)
    function _generateMultipliers(uint256 tokenId) internal {
        uint256 randNum = _generateRandNum(tokenId);

        stats[tokenId].farmingMultiplier = uint8(randNum % 1000)+1;
        randNum = _generateRandNum(tokenId);
        stats[tokenId].trainingMultiplier = uint8(randNum % 1000)+1;
    }

    function flipPause() external onlyOwner {
        if (paused()) _unpause();
        else _pause();
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setContractAddresses(address _warrior, address _resource) external onlyOwner {
        warrior = Warrior(_warrior);
        resource = RESOURCE(_resource);
    }

    function changeBaseURI(string memory _baseuri) external onlyOwner {
        baseURI = _baseuri;
    }

    // function setVars(
    //     uint64 _resourceRate, 
    //     uint128 _maxCirculating, 
    //     uint16 _baseFarmingEXP, 
    //     uint16 _baseTrainingEXP, 
    //     uint32 _time) 
    //     external onlyOwner {
    //         BASE_RESOURCE_RATE = _resourceRate;
    //         MAX_RESOURCE_CIRCULATING = _maxCirculating;
    //         BASE_FARMING_EXP = _baseFarmingEXP;
    //         BASE_TRAINING_EXP = _baseTrainingEXP;
    //         BASE_TIME = _time;
    // }
}