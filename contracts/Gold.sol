// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract Gold is ERC20, ERC20Burnable, Pausable, Ownable, ERC20Permit {
    constructor() ERC20("Gold", "GLD") ERC20Permit("Gold") {
        gameMasters[owner()] = true;
    }

    mapping(address => bool) gameMasters;

    modifier onlyGM() {
        require(gameMasters[msg.sender] == true, "Not a game master!");
        _;
    }

    function mint(address to, uint256 amount) public onlyGM {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyGM {
        _burn(from, amount);
    }

    function editGameMaster(address user, bool gm) external onlyOwner {
        gameMasters[user] = gm;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}