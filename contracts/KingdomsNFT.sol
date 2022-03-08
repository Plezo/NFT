// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract KingdomsNFT is ERC721A, Ownable, ReentrancyGuard {

    uint256 public price = 0.08 ether;
    bool public saleLive = false;
    constructor() ERC721A("KingdomsNFT", "KNFT") {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function publicMint(uint256 amount) external payable {
        require(msg.value >= price, "Not enough ETH!");
        _safeMint(msg.sender, amount);
        _refund();
    }

    function _refund() internal {
        require(msg.value >= price);
        payable(msg.sender).transfer(msg.value - price);
    }
}