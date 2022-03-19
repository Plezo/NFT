// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RESOURCE is ERC20, Ownable {
    constructor() ERC20("GOLD", "GOLD") {
        gameMasters[owner()] = true;
    }

    mapping(address => bool) gameMasters;

    modifier onlyGM() {
        require(gameMasters[msg.sender] == true, "Not a game master!");
        _;
    }

    function mint(address to, uint256 amount) external onlyGM {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyGM {
        _burn(from, amount);
    }

    function editGameMasters(address[] memory users, bool[] memory gms) external onlyGM {
        for (uint256 i; i < users.length; i++) {
            gameMasters[users[i]] = gms[i];
        }
    }
}