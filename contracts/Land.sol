// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './Warrior.sol';
import './RESOURCE.sol';
import './Staking.sol';

contract Land is ERC721A, ERC721ABurnable, Ownable, ReentrancyGuard {
    Warrior warrior;
    RESOURCE resource;
    Staking staking;

    string public baseURI = "";

    struct LandStats {
        uint8 farmingMultiplier;
        uint8 trainingMultiplier;
    }

    mapping(uint256 => LandStats) public stats;

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


    /*
        ██ ███    ██ ████████ ███████ ██████  ███    ██  █████  ██      
        ██ ████   ██    ██    ██      ██   ██ ████   ██ ██   ██ ██      
        ██ ██ ██  ██    ██    █████   ██████  ██ ██  ██ ███████ ██      
        ██ ██  ██ ██    ██    ██      ██   ██ ██  ██ ██ ██   ██ ██      
        ██ ██   ████    ██    ███████ ██   ██ ██   ████ ██   ██ ███████ 
    */

    function getStats(uint256 tokenId) external view returns(uint8, uint8) {
        return (stats[tokenId].farmingMultiplier, stats[tokenId].trainingMultiplier);
    }

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
        require(msg.sender == owner() || msg.sender == address(staking), "Not owner!");

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

        stats[tokenId].farmingMultiplier = uint8(randNum % 100)+101;
        randNum = _generateRandNum(tokenId);
        stats[tokenId].trainingMultiplier = uint8(randNum % 100)+101;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setContractAddresses(address _warrior, address _resource, address _staking) external onlyOwner {
        warrior = Warrior(_warrior);
        resource = RESOURCE(_resource);
        staking = Staking(_staking);
    }

    function changeBaseURI(string memory _baseuri) external onlyOwner {
        baseURI = _baseuri;
    }
}