// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "./ERC721ABurnable.sol";

contract Land is ERC721A, ERC721ABurnable, Ownable, ReentrancyGuard {

    string public baseURI = "";

    struct LandStats {
        uint8 farmingMultiplier;
        uint8 trainingMultiplier;
    }

    mapping(uint256 => LandStats) public stats;

    event TokenStaked(address owner, uint16 landTokenId, uint32 timeStaked, uint16[3] warriorTokenIds, uint8[3] _actions);

    constructor(string memory _baseuri) ERC721A("Land", "LAND") { 
        baseURI = _baseuri;
    }

    /*
        ██████  ██    ██ ██████  ██      ██  ██████ 
        ██   ██ ██    ██ ██   ██ ██      ██ ██      
        ██████  ██    ██ ██████  ██      ██ ██      
        ██      ██    ██ ██   ██ ██      ██ ██      
        ██       ██████  ██████  ███████ ██  ██████ 
    */

    function getLandStats(uint256 tokenId) external view returns(uint8, uint8) {
        return (stats[tokenId].farmingMultiplier, stats[tokenId].trainingMultiplier);
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

    /*
         ██████  ██     ██ ███    ██ ███████ ██████  
        ██    ██ ██     ██ ████   ██ ██      ██   ██ 
        ██    ██ ██  █  ██ ██ ██  ██ █████   ██████  
        ██    ██ ██ ███ ██ ██  ██ ██ ██      ██   ██ 
         ██████   ███ ███  ██   ████ ███████ ██   ██ 
    */

    function mintLand(address _to, uint256 _amount) external {
        require(msg.sender == owner() || _isGameContract(msg.sender), "MintLand: Not owner!");

        uint256 firstTokenId = _currentIndex;
        for (uint256 i; i < _amount; i++)
            _generateMultipliers(firstTokenId+i);

        _safeMint(_to, _amount);
    }

    function _generateRandNum(uint256 randNum, uint256 tokenId) internal view returns(uint256) {
        uint256 seed = 
            uint256(keccak256(abi.encodePacked(randNum, msg.sender, tokenId, block.timestamp, block.difficulty)));
        return(uint256(keccak256(abi.encode(seed, tokenId))));
    }

    // consider adding weights to intervals (i.e. 10% to have >800)
    function _generateMultipliers(uint256 tokenId) internal {
        uint256 randNum = _generateRandNum(block.timestamp, tokenId);

        stats[tokenId].farmingMultiplier = uint8(randNum % 100)+101;
        randNum = _generateRandNum(randNum, tokenId);
        stats[tokenId].trainingMultiplier = uint8(randNum % 100)+101;
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