// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './KingdomsNFT.sol';
import './GOLD.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

contract Land is IERC721Receiver, Pausable, Ownable {

    // idk if team wants this constant, if not then create setter functions
    uint256 public DAILY_GOLD_RATE = 100 ether;
    uint256 public MAX_GOLD_CIRCULATING = 1000000 ether;

    KingdomsNFT knft;
    GOLD gold;

    struct Stake {
        address owner;
        uint256 tokenId;
        uint256 timeStaked;
    }

    mapping(uint256 => Stake) land;

    event TokenStaked(address owner, uint256 tokenId, uint256 timeStaked);

    constructor(address _knft, address _gold) { 
        knft = KingdomsNFT(_knft);
        gold = GOLD(_gold);
    }

    function stake(address from, uint256 tokenId) external whenNotPaused {
        land[tokenId] = Stake({
            owner: from,
            tokenId: tokenId,
            timeStaked: block.timestamp
        });

        knft.transferFrom(from, address(this), tokenId); // this contract needs to be approved
        
        emit TokenStaked(from, tokenId, block.timestamp);
    }

    function unstake(uint256 tokenId) external whenNotPaused {
        require(msg.sender == land[tokenId].owner);

        knft.transferFrom(address(this), land[tokenId].owner, tokenId);
        delete land[tokenId];
    }

    function claim(uint256 tokenId) external whenNotPaused {
        require(land[tokenId].tokenId == tokenId);
        require(msg.sender == land[tokenId].owner);

        uint256 claimAmount = 
            (block.timestamp - land[tokenId].timeStaked)
            * (DAILY_GOLD_RATE / 1 days);

        gold.mint(msg.sender, claimAmount);
    }

    function flipPause() external onlyOwner {
        if (paused()) _unpause();
        else _pause();
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
      require(from == address(0x0), "Cannot send tokens to Barn directly");
      return IERC721Receiver.onERC721Received.selector;
    }

}