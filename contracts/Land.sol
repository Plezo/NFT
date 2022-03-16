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

    uint96 public BASE_RESOURCE_RATE = 100 ether;
    uint128 public MAX_RESOURCE_CIRCULATING = 1000000 ether;
    uint32 public BASE_TIME = 1 days;

    Warrior warrior;
    RESOURCE resource;

    struct Stake {
        uint16 landTokenId;
        address owner;
        uint32 timeStaked;
        uint16[3] warriorTokenIds; // if we max stake at 3 warriors, this stake will be efficient
    }

    mapping(uint256 => Stake) public land;

    event TokenStaked(address owner, uint16 landTokenId, uint32 timeStaked);

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

    function stakeLand(uint16 _landTokenId, uint16[3] memory _warriorTokenIds) external whenNotPaused {
        require(msg.sender == ownerOf(_landTokenId), "Cant stake someone elses token!");
        require(!(land[_landTokenId].owner == msg.sender), "Already have a land staked!");

        _stakeLand(msg.sender, _landTokenId, _warriorTokenIds);
    }

    function claimResource(uint256 _landTokenId, bool unstake) external whenNotPaused {
        require(land[_landTokenId].landTokenId == _landTokenId, "Not staked!");
        require(land[_landTokenId].owner == msg.sender, "Can't claim for someone else!");

        _claimResource(msg.sender, _landTokenId);

        if (unstake) _unstake(msg.sender, _landTokenId);
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

    function _stakeLand(address _from, uint16 _landTokenId, uint16[3] memory _warriorTokenIds) internal {
        land[_landTokenId] = Stake({
            landTokenId: _landTokenId,
            owner: _from,
            timeStaked: uint32(block.timestamp),
            warriorTokenIds: _warriorTokenIds 
        });

        _transfer(_from, address(this), _landTokenId);
        emit TokenStaked(_from, _landTokenId, uint32(block.timestamp));
    }

    function _unstake(address _from, uint256 _landTokenId) internal {
        transferFrom(address(this), _from, _landTokenId);
        delete land[_landTokenId];
    }

    function _claimResource(address _from, uint256 _landTokenId) internal {
        uint256 claimAmount = 
            (block.timestamp - land[_landTokenId].timeStaked)
            * (BASE_RESOURCE_RATE / BASE_TIME);

        require(resource.totalSupply() + claimAmount <= MAX_RESOURCE_CIRCULATING, "Max resource supply reached!");

        resource.mint(_from, claimAmount);
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

    function mintLand(address _to, uint256 _amount) external {
        require(msg.sender == owner() || msg.sender == address(warrior), "Not owner!");

        _safeMint(_to, _amount);
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

    function setBaseTime(uint32 _time) external onlyOwner {
        BASE_TIME = _time;
    }
}