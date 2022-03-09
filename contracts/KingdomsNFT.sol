// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract KingdomsNFT is ERC721A, ERC721ABurnable, Ownable, ReentrancyGuard {

    uint256 public MAX_SUPPLY = 8888;  // consider making immutable

    uint256 public price = 0.08 ether;
    bool public saleLive = false;
    constructor() ERC721A("KingdomsNFT", "KNFT") {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function publicMint(uint256 amount) external payable {
        require(saleLive == true, "Sale is not live!");
        require(tx.origin ==  msg.sender, "No contract mints!");
        require(this.totalSupply() + amount <= MAX_SUPPLY, "Max supply reached!");
        require(msg.value == price * amount, "Incorrect ETH amount!");
        
        _safeMint(msg.sender, amount);
    }

    function flipSaleState() external onlyOwner {
        saleLive = !saleLive;
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Not enough ETH to withdraw!");

        if (amount == 0) payable(msg.sender).transfer(address(this).balance);
        else payable(msg.sender).transfer(amount);
    }
}