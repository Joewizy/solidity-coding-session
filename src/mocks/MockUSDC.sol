// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockUSDC
 * @notice Test-only ERC-20 with 6 decimals and open mint.
 *         DO NOT deploy to mainnet.
 */
contract MockUSDC is ERC20 {
    constructor() ERC20("USD Coin", "USDC") {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    /// @notice Anyone can mint — test environment only.
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /// @notice Anyone can burn — test environment only.
    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}
