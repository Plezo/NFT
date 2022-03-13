// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./GOLD.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/security/Pausable.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract KingdomsNFT is ERC721A, ERC721ABurnable, Ownable, Pausable, ReentrancyGuard {

    uint256 public MAX_SUPPLY = 8888;  // consider making immutable
    uint256 public DAILY_GOLD_RATE = 100 ether;
    uint256 public MAX_GOLD_CIRCULATING = 1000000 ether;

    uint256 public price = 0.08 ether;
    bool public saleLive = false;

    GOLD public gold;

    mapping(uint256 => Stake) land;

    struct Stake {
        address owner;
        uint256 tokenId;
        uint256 timeStaked;
    }

    event TokenStaked(address owner, uint256 tokenId, uint256 timeStaked);

    /*


    */
    
    constructor() ERC721A("KingdomsNFT", "KNFT") {
        gold = new GOLD();
        gold.editGameMaster(address(msg.sender), true);
    }
    
    /*
        ██████  ██    ██ ██████  ██      ██  ██████ 
        ██   ██ ██    ██ ██   ██ ██      ██ ██      
        ██████  ██    ██ ██████  ██      ██ ██      
        ██      ██    ██ ██   ██ ██      ██ ██      
        ██       ██████  ██████  ███████ ██  ██████ 
    */

    function publicMint(uint256 amount) external payable {
        require(saleLive, "Sale is not live!");
        require(tx.origin ==  msg.sender, "No contract mints!");
        require(this.totalSupply() + amount <= MAX_SUPPLY, "Max supply reached!");
        require(msg.value == price * amount, "Incorrect ETH amount!");
        
        _safeMint(msg.sender, amount);
    }

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
         ██████  ██     ██ ███    ██ ███████ ██████  
        ██    ██ ██     ██ ████   ██ ██      ██   ██ 
        ██    ██ ██  █  ██ ██ ██  ██ █████   ██████  
        ██    ██ ██ ███ ██ ██  ██ ██ ██      ██   ██ 
         ██████   ███ ███  ██   ████ ███████ ██   ██ 
    */

    function flipSaleState() external onlyOwner {
        saleLive = !saleLive;
    }

    function flipPause() external onlyOwner {
        if (paused()) _unpause();
        else _pause();
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Not enough ETH to withdraw!");

        if (amount == 0) payable(msg.sender).transfer(address(this).balance);
        else payable(msg.sender).transfer(amount);
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

        gold.mint(to, claimAmount);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }
}