// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is Pausable, ERC20, Ownable {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    // Overrides ERC20 checks for avoiding tokens to be transferred

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._transfer(from, to, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal override whenNotPaused {
        super._approve(owner, spender, amount);
    }

    // Pausable

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Mintable & Burnable

    function mint(address to, uint256 amount)
        external
        onlyOwner
        returns (bool)
    {
        super._mint(to, amount);

        return true;
    }

    function burn(uint256 amount) external onlyOwner returns (bool) {
        super._burn(owner(), amount);

        return true;
    }
}
