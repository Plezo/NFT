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

    Land land;
    RESOURCE resource;

    // consider using byte array instead of enum
    enum   Actions { UNSTAKED, SCOUTING, FARMING, TRAINING }
    struct Action  {
        address owner;
        uint64 timeStarted;
        Actions action;
    }

    mapping (uint256 => bool) public landClaimed;
    mapping (uint256 => Action) public activities;
    
    constructor() ERC721A("KingdomsNFT", "KNFT") {}
    
    /*
        ██████  ██    ██ ██████  ██      ██  ██████ 
        ██   ██ ██    ██ ██   ██ ██      ██ ██      
        ██████  ██    ██ ██████  ██      ██ ██      
        ██      ██    ██ ██   ██ ██      ██ ██      
        ██       ██████  ██████  ███████ ██  ██████ 
    */

    function changeAction(uint256 tokenId, Actions action) external {
        _changeAction(msg.sender, tokenId, action);
    }

    function massChangeAction(uint256[] memory tokenIds, Actions[] memory actions) external {
        require(tokenIds.length == actions.length, "Must have an action per id!");

        for (uint256 i; i < tokenIds.length; i++) {
            _changeAction(msg.sender, tokenIds[i], actions[i]);
        }
    }

    function publicMint(uint256 amount, bool scout) external payable {
        require(saleLive, "Mint: Sale is not live!");
        require(tx.origin ==  msg.sender, "Mint: No contract mints!");
        require(this.totalSupply() + amount <= MAX_SUPPLY, "Mint: Max supply reached!");
        require(0 < amount && amount <= maxPerTx, "Mint: Invalid amount entered!");
        require(msg.value == price * amount, "Mint: Incorrect ETH amount!");
    

        if (scout) {
            uint256[3] memory tokenIds;
            for (uint256 i; i < amount; i++) {
                tokenIds[i] = _currentIndex + i;
            }

            _safeMint(msg.sender, amount);

            for (uint256 i; i < amount; i++)
                _changeAction(msg.sender, tokenIds[i], Actions.SCOUTING);
        }
        else {
            _safeMint(msg.sender, amount);
        }
    }

    // currently auto unstakes, may change in future
    function claimLand(uint256 tokenId) external {
        require(activities[tokenId].owner == msg.sender, "Claim: Can't claim someone elses land!");
        require(!landClaimed[tokenId], "Claim: Land already claimed for tokenId!");
        require(block.timestamp > activities[tokenId].timeStarted + landClaimTime, "Claim: Need to scout for 24 hours!");

        land.mintLand(msg.sender);
        landClaimed[tokenId] = true;
        _changeAction(msg.sender, tokenId, Actions.UNSTAKED);
    }

    // wip
    // function claimLand(uint256 tokenId, bool stakeLand, Actions warriorAction) external {}

    function transferFrom(
    address from,
    address to,
    uint256 tokenId
    ) public virtual override {
        if (from == address(this) && activities[tokenId].owner == msg.sender)
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

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function _changeAction(address from, uint256 tokenId, Actions action) internal {
        require(ownerOf(tokenId) == from || activities[tokenId].owner == from, "Must be owner of token!");
        require(activities[tokenId].action != action, "Already performing that action!");

        activities[tokenId] = Action({
            owner: from,
            timeStarted: uint64(block.timestamp),
            action: action
        });

        if (action == Actions.UNSTAKED) transferFrom(address(this), from, tokenId);
        else {
            if (action == Actions.SCOUTING) require(!landClaimed[tokenId], "Land already claimed for token!");
            _transfer(from, address(this), tokenId);
        }
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
        land = Land(_land);
        resource = RESOURCE(_resource);
    }

    function setLandClaimTime(uint32 _time) external onlyOwner {
        landClaimTime = _time;
    }
}