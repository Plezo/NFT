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

    uint256 public totalStaked;
    uint256 public numGoldCirculating;
    uint256 public lastClaimTimestamp;

    KingdomsNFT knft;
    GOLD gold;

    struct Stake {
        address owner;
        uint256 tokenId;
        uint256 timeStaked;
    }

    mapping(uint256 => Stake) land;

    // idk if we need
    event TokenStaked(address owner, uint256 tokenId, uint256 timeStaked);

    constructor(address _knft, address _gold) { 
        knft = KingdomsNFT(_knft);
        gold = GOLD(_gold);
    }

    // reconsider this, find another way of generating gold
    modifier _updateEarnings() {
        if (numGoldCirculating < MAX_GOLD_CIRCULATING) {
            numGoldCirculating += 
            (block.timestamp - lastClaimTimestamp)
            * totalStaked
            * DAILY_GOLD_RATE / 1 days; 
        lastClaimTimestamp = block.timestamp;
        }
        _;
    }

    function stake(address from, uint256 tokenId) external whenNotPaused _updateEarnings {
        land[tokenId] = Stake({
            owner: from,
            tokenId: tokenId,
            timeStaked: block.timestamp
        });
        totalStaked += 1;
        emit TokenStaked(from, tokenId, block.timestamp);
    }

    // wip
    function claim() external {

    }

    function flipPause() external onlyOwner {
        if (paused()) _unpause();
        else if (!paused()) _pause();
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