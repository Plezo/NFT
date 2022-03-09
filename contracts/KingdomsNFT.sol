// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract KingdomsNFT is ERC721A, ERC721ABurnable, Ownable, ReentrancyGuard {

    uint256 public price = 0.08 ether;
    bool public saleLive = false;
    constructor() ERC721A("KingdomsNFT", "KNFT") {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function flipSaleState() external onlyOwner {
        saleLive = !saleLive;
    }

    function publicMint(uint256 amount) external payable {
        require(msg.value == price * amount, "Incorrect ETH amount!");
        require(saleLive == true, "Sale is not live!");
        
        _safeMint(msg.sender, amount);
    }
}