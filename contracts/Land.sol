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

    uint256 public BASE_RESOURCE_RATE = 100 ether;
    uint256 public MAX_RESOURCE_CIRCULATING = 1000000 ether;
    uint256 public BASE_TIME = 1 days;

    Warrior warrior;
    RESOURCE resource;

    struct Stake {
        address owner;
        uint256 tokenId;
        uint256 timeStaked;
    }

    mapping(uint256 => Stake) public land;

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

    function stakeLand(uint256 tokenId) external whenNotPaused {
        require(msg.sender == ownerOf(tokenId), "Cant stake someone elses token!");
        require(!(land[tokenId].owner == msg.sender), "Already have a land staked!");

        _stakeLand(msg.sender, tokenId);
    }

    function claimResource(uint256 tokenId, bool unstake) external whenNotPaused {
        require(land[tokenId].tokenId == tokenId, "Not staked!");
        require(land[tokenId].owner == msg.sender, "Can't claim for someone else!");

        _claimResource(msg.sender, tokenId);

        if (unstake) _unstake(msg.sender, tokenId);
    }

    function transferFrom(
    address from,
    address to,
    uint256 tokenId
    ) public virtual override {
        if (from == address(this) && land[tokenId].owner == msg.sender)
            _approve(to, tokenId, msg.sender);
        _transfer(from, to, tokenId);
    }

    /*
        ██ ███    ██ ████████ ███████ ██████  ███    ██  █████  ██      
        ██ ████   ██    ██    ██      ██   ██ ████   ██ ██   ██ ██      
        ██ ██ ██  ██    ██    █████   ██████  ██ ██  ██ ███████ ██      
        ██ ██  ██ ██    ██    ██      ██   ██ ██  ██ ██ ██   ██ ██      
        ██ ██   ████    ██    ███████ ██   ██ ██   ████ ██   ██ ███████ 
    */

    function _stakeLand(address from, uint256 tokenId) internal {
        land[tokenId] = Stake({
            owner: from,
            tokenId: tokenId,
            timeStaked: block.timestamp
        });

        _transfer(from, address(this), tokenId);
        emit TokenStaked(from, tokenId, block.timestamp);
    }

    function _unstake(address from, uint256 tokenId) internal {
        transferFrom(address(this), from, tokenId);
        delete land[tokenId];
    }

    function _claimResource(address from, uint256 tokenId) internal {
        uint256 claimAmount = 
            (block.timestamp - land[tokenId].timeStaked)
            * (BASE_RESOURCE_RATE / BASE_TIME);

        require(resource.totalSupply() + claimAmount <= MAX_RESOURCE_CIRCULATING, "Max resource supply reached!");

        resource.mint(from, claimAmount);
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

    function mintLand(address to) external {
        require(msg.sender == owner() || msg.sender == address(warrior), "Not owner!");

        _safeMint(to, 1);
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

    function setBaseTime(uint256 time) external onlyOwner {
        BASE_TIME = time;
    }
}