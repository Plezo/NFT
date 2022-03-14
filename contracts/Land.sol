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

    // idk if team wants this constant, if not then create setter functions
    uint256 public DAILY_GOLD_RATE = 100 ether;
    uint256 public MAX_GOLD_CIRCULATING = 1000000 ether;

    Warrior warrior;
    RESOURCE resource;

    struct Stake {
        address owner;
        uint256 tokenId;
        uint256 timeStaked;
    }

    mapping(uint256 => Stake) land;

    event TokenStaked(address owner, uint256 tokenId, uint256 timeStaked);

    constructor(address _warrior, address _resource) ERC721A("Land", "LAND") { 
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

    function stake(uint256 tokenId) external whenNotPaused {
        require(msg.sender == ownerOf(tokenId), "Cant stake someone elses token!");

        _stake(msg.sender, tokenId);
    }

    function claim(uint256 tokenId, bool unstake) external whenNotPaused {
        require(land[tokenId].tokenId == tokenId, "Not staked!");
        require(msg.sender == land[tokenId].owner, "Can't claim for someone else!");

        _claim(msg.sender, tokenId);

        if (unstake) _unstake(tokenId);
    }

    /*
        ██ ███    ██ ████████ ███████ ██████  ███    ██  █████  ██      
        ██ ████   ██    ██    ██      ██   ██ ████   ██ ██   ██ ██      
        ██ ██ ██  ██    ██    █████   ██████  ██ ██  ██ ███████ ██      
        ██ ██  ██ ██    ██    ██      ██   ██ ██  ██ ██ ██   ██ ██      
        ██ ██   ████    ██    ███████ ██   ██ ██   ████ ██   ██ ███████ 
    */

    function _stake(address from, uint256 tokenId) internal {
        land[tokenId] = Stake({
            owner: from,
            tokenId: tokenId,
            timeStaked: block.timestamp
        });

        transferFrom(from, address(this), tokenId);

        emit TokenStaked(from, tokenId, block.timestamp);
    }

    function _unstake(uint256 tokenId) internal {
        transferFrom(address(this), land[tokenId].owner, tokenId);
        delete land[tokenId];
    }

    function _claim(address to, uint256 tokenId) internal {
        uint256 claimAmount = 
            (block.timestamp - land[tokenId].timeStaked)
            * (DAILY_GOLD_RATE / 1 days);

        resource.mint(to, claimAmount);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    /*
         ██████  ██     ██ ███    ██ ███████ ██████  
        ██    ██ ██     ██ ████   ██ ██      ██   ██ 
        ██    ██ ██  █  ██ ██ ██  ██ █████   ██████  
        ██    ██ ██ ███ ██ ██  ██ ██ ██      ██   ██ 
         ██████   ███ ███  ██   ████ ███████ ██   ██ 
    */

    function flipPause() external onlyOwner {
        if (paused()) _unpause();
        else _pause();
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}