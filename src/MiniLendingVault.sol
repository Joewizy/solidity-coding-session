// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title  MiniLendingVault
 * @notice Technical interview exercise — a simplified lending vault.
 *
 * Decimals
 *   USDC has 6 decimals. Vault shares have 18 (default ERC20). You will need
 *   to bridge the gap explicitly in `deposit` and in `sharePriceUSDC`.
 *
 * Reflexivity (read before writing math)
 *   Share price = totalSupplied / totalSupply(). Borrowing reduces
 *   totalSupplied (USDC leaves the vault), which reduces share price, which
 *   reduces the borrower's own collateral value. A max-LTV borrow can leave
 *   the borrower instantly liquidatable. INTENTIONAL — Task 4 explicitly
 *   grades how you reason about the bad-debt scenario this creates. Do not
 *   "fix" the reflexivity. If you would design this differently in
 *   production, mention it in your trade-off note instead.
 */
contract MiniLendingVault is ERC20 {
    using SafeERC20 for IERC20;

    // ── Immutables ───────────────────────────────────────────────────────

    IERC20 public immutable USDC;

    // ── Risk parameters ──────────────────────────────────────────────────

    /// @notice Max loan-to-value at borrow time (75%).
    /// a user can borrow up to 75% of their collateral value
    uint256 public constant MAX_LTV_BPS = 7500; // 75%
    /// @notice Health-factor weighting (80%).
    /// a user is liquidatable if their health factor is less than 80%
    uint256 public constant LIQ_THRESHOLD_BPS = 8000; // 80%
    /// @notice Denominator for BPS math. | 10000 = 100%, 1000 = 10%, 5000 = 50%
    uint256 public constant BPS_DENOMINATOR = 10_000; // 100%
    /// @notice Scale factor for the health-factor return value. | 1e18 = 100%
    uint256 public constant HF_SCALE = 1e18; // 100%

    // ── State ────────────────────────────────────────────────────────────

    /// @notice Total USDC currently held by the vault as supply
    ///         (deposits + repayments − borrows still outstanding).
    uint256 public totalSupplied;

    /// @notice Outstanding debt per user, denominated in USDC (6 decimals).
    mapping(address => uint256) public debtOf;

    // ── Errors (suggested — add more as you see fit) ─────────────────────

    error ZeroAmount();
    error InsufficientCollateral();
    error NotLiquidatable();
    error WouldBeLiquidatable();

    // ── Events (suggested — add more as you see fit) ─────────────────────

    event Deposited(address indexed user, uint256 assets, uint256 shares);
    event Withdrawn(address indexed user, uint256 shares, uint256 assets);
    event Borrowed(address indexed user, uint256 amount);
    event Liquidated(address indexed liquidator, address indexed user, uint256 debtRepaid, uint256 sharesSeized);

    // ── Constructor ──────────────────────────────────────────────────────

    constructor(address _usdc) ERC20("Mini Vault Share", "mvSHARE") {
        USDC = IERC20(_usdc);
    }

    // ════════════════════════════════════════════════════════════════════
    //
    //  TASK 1 — deposit
    //
    //  Pull `assets` USDC from the caller and mint vault shares ERC-4626 style.
    //
    //  Requirements:
    //    • Revert on zero amount.
    //    • On the very first deposit, mint shares such that 1 USDC ≈ 1 share
    //      (you must bridge the 6→18 decimal gap).
    //    • On subsequent deposits, shares minted = assets × totalSupply() / totalSupplied
    //      (i.e. proportional to the current share price).
    //    • Use SafeERC20 for the USDC transfer.
    //    • Update totalSupplied.
    //    • Emit Deposited.
    //
    //  Return the number of shares minted.
    //
    // ════════════════════════════════════════════════════════════════════
    function deposit(uint256 assets) external returns (uint256 sharesMinted) {
        // TODO
    }

    // ════════════════════════════════════════════════════════════════════
    //
    //  TASK 2 — borrow
    //
    //  Caller borrows USDC using their existing share balance as collateral.
    //
    //  Requirements:
    //    • Revert on zero amount.
    //    • Compute the caller's collateral value in USDC from their share
    //      balance and the current share price.
    //    • The caller's *total* debt (existing + new) must not push their LTV
    //      above MAX_LTV_BPS at the moment of the borrow.
    //    • Transfer USDC to the caller using SafeERC20.
    //    • Update debtOf and totalSupplied appropriately.
    //    • Emit Borrowed.
    //
    // ════════════════════════════════════════════════════════════════════
    function borrow(uint256 amount) external {
        // TODO
    }

    // ════════════════════════════════════════════════════════════════════
    //
    //  TASK 3 — getHealthFactor
    //
    //  Health factor formula:
    //
    //      HF = (collateralValueUSDC × LIQ_THRESHOLD_BPS × HF_SCALE)
    //           / (debtUSDC × BPS_DENOMINATOR)
    //
    //  Returns 1e18 when collateral × LIQ_THRESHOLD exactly equals debt × BPS_DENOMINATOR.
    //  Values < 1e18 mean the user is liquidatable.
    //
    //  Requirements:
    //    • If the user has no debt, return type(uint256).max ("infinitely healthy").
    //    • Otherwise compute and return the scaled HF.
    //
    // ════════════════════════════════════════════════════════════════════
    function getHealthFactor(address user) public view returns (uint256) {
        // TODO
    }

    // ════════════════════════════════════════════════════════════════════
    //
    //  TASK 4 — liquidate
    //
    //  If `user`'s health factor < 1e18, anyone may call this function.
    //  The liquidator pays the user's full debt in USDC and receives all of
    //  the user's shares (simplified — no partial liquidations, no bonus).
    //
    //  Requirements:
    //    • Revert if the user is not liquidatable.
    //    • Pull the debt amount in USDC from the liquidator.
    //    • Zero out the user's debt.
    //    • Transfer all of the user's shares to the liquidator.
    //    • Update totalSupplied appropriately.
    //    • Emit Liquidated.
    //
    //  Edge case you MUST address:
    //    • What happens when the user's share collateral is worth LESS than
    //      their debt at liquidation time? (bad-debt scenario — see the
    //      reflexivity note at the top of this file for why this is the
    //      common case, not a rare one.)
    //    • Explain in a comment what your contract does about it and why.
    //      There are at least three reasonable choices — pick one and justify it.
    //
    // ════════════════════════════════════════════════════════════════════
    function liquidate(address user) external {
        // TODO
    }

    // ════════════════════════════════════════════════════════════════════
    //
    //  TASK 5 — withdraw
    //
    //  Caller burns `shares` and receives the corresponding USDC.
    //
    //  Requirements:
    //    • Revert on zero amount.
    //    • Compute the USDC amount owed using the current share price.
    //    • Burn the caller's shares (revert via ERC20 if balance too low).
    //    • Update totalSupplied.
    //    • Transfer USDC to the caller using SafeERC20.
    //    • Emit Withdrawn.
    //    • The caller's health factor AFTER the burn must remain ≥ 1e18.
    //      Withdrawing collateral that would put the caller underwater must
    //      revert with WouldBeLiquidatable.
    //
    //  Note: this function does not handle "withdraw exact USDC amount" — only
    //  "burn this many shares". The latter is simpler; the former is a common
    //  follow-up you might implement in production.
    //
    // ════════════════════════════════════════════════════════════════════
    function withdraw(uint256 shares) external returns (uint256 assetsReturned) {
        // TODO
    }

    // ════════════════════════════════════════════════════════════════════
    //  Helper views — provided. USE these in your task implementations.
    //
    //  Do NOT modify the bodies of `sharePriceUSDC` or `collateralValueUSDC`:
    //  the grading tests assume this exact math (the 6→18 decimal bridge is
    //  encoded here so you don't have to re-derive it in every function).
    //
    //  If you change them, you'll quietly fail downstream tests for borrow,
    //  withdraw, getHealthFactor, and liquidate even when your task logic
    //  is otherwise correct.
    // ════════════════════════════════════════════════════════════════════

    /// @notice USDC value of 1e18 shares (share price in USDC, 6-decimal output).
    function sharePriceUSDC() public view returns (uint256) {
        // 1 share = 1 USDC initially if no shares are minted
        if (totalSupply() == 0) return 1e6;
        return (totalSupplied * 1e18) / totalSupply();
    }

    /// @notice USDC value of a user's entire share balance.
    function collateralValueUSDC(address user) public view returns (uint256) {
        return (balanceOf(user) * sharePriceUSDC()) / 1e18;
    }
}
