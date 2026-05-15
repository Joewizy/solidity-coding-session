// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";

import {MiniLendingVault} from "../src/MiniLendingVault.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";

/**
 * Starter tests for MiniLendingVault.
 *
 * These show the expected API shape and a few baseline behaviors.
 * They will FAIL until you implement the TODO functions in MiniLendingVault.sol.
 *
 * You are encouraged (but not required) to add more tests of your own:
 *   - Borrow at exactly MAX_LTV (boundary)
 *   - Liquidation happy-path (someone goes underwater, liquidator seizes shares)
 *   - Bad-debt scenario (collateral worth < debt at liquidation time)
 *   - Withdraw blocked when it would push HF below 1e18
 *
 * Tests you write count toward grading.
 */
contract MiniLendingVaultTest is Test {
    MockUSDC internal usdc;
    MiniLendingVault internal vault;

    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");

    function setUp() public {
        usdc = new MockUSDC();
        vault = new MiniLendingVault(address(usdc));

        usdc.mint(alice, 1_000_000e6);
        usdc.mint(bob, 1_000_000e6);

        vm.prank(alice);
        usdc.approve(address(vault), type(uint256).max);

        vm.prank(bob);
        usdc.approve(address(vault), type(uint256).max);
    }

    // ── deposit ──────────────────────────────────────────────────────────

    function test_firstDeposit_mintsAtOneToOneAcrossDecimalBridge() public {
        vm.prank(alice);
        uint256 shares = vault.deposit(100e6); // 100 USDC

        assertEq(shares, 100e18, "shares minted");
        assertEq(vault.balanceOf(alice), 100e18, "alice share balance");
        assertEq(vault.totalSupply(), 100e18, "total supply");
        assertEq(vault.totalSupplied(), 100e6, "totalSupplied");
        assertEq(usdc.balanceOf(address(vault)), 100e6, "vault USDC balance");
    }

    function test_deposit_revertsOnZero() public {
        vm.prank(alice);
        vm.expectRevert(MiniLendingVault.ZeroAmount.selector);
        vault.deposit(0);
    }

    // ── health factor ────────────────────────────────────────────────────

    function test_healthFactor_noDebt_returnsMax() public {
        vm.prank(alice);
        vault.deposit(100e6);

        assertEq(vault.getHealthFactor(alice), type(uint256).max, "no debt => max HF");
    }

    // ── borrow ───────────────────────────────────────────────────────────

    function test_borrow_revertsOnZero() public {
        vm.prank(alice);
        vault.deposit(100e6);

        vm.prank(alice);
        vm.expectRevert(MiniLendingVault.ZeroAmount.selector);
        vault.borrow(0);
    }

    function test_borrow_atMaxLTV_succeeds() public {
        vm.prank(alice);
        vault.deposit(100e6); // 100 USDC collateral, share price = 1 USDC

        uint256 aliceUsdcBefore = usdc.balanceOf(alice);

        vm.prank(alice);
        vault.borrow(75e6); // exactly 75% LTV

        assertEq(vault.debtOf(alice), 75e6, "alice debt");
        assertEq(usdc.balanceOf(alice), aliceUsdcBefore + 75e6, "alice received USDC");
        assertEq(vault.totalSupplied(), 25e6, "totalSupplied dropped");
    }

    function test_borrow_aboveMaxLTV_reverts() public {
        vm.prank(alice);
        vault.deposit(100e6);

        // 1 wei of USDC over the 75% cap.
        vm.prank(alice);
        vm.expectRevert(MiniLendingVault.InsufficientCollateral.selector);
        vault.borrow(80e6);
    }

    function test_borrow_secondBorrow_countsExistingDebt() public {
        vm.prank(alice);
        vault.deposit(100e6);

        vm.prank(alice);
        vault.borrow(50e6); // 50% LTV

        // Existing debt 50, attempting +30 → total 80 > 75% cap. Must revert.
        vm.prank(alice);
        vm.expectRevert(MiniLendingVault.InsufficientCollateral.selector);
        vault.borrow(30e6);
    }

    // ── withdraw ─────────────────────────────────────────────────────────

    function test_withdraw_revertsOnZero() public {
        vm.prank(alice);
        vault.deposit(100e6);

        vm.prank(alice);
        vm.expectRevert(MiniLendingVault.ZeroAmount.selector);
        vault.withdraw(0);
    }

    function test_withdraw_fullBalance_noDebt_refundsAllUSDC() public {
        uint256 aliceUsdcBefore = usdc.balanceOf(alice);

        vm.prank(alice);
        vault.deposit(100e6);

        vm.prank(alice);
        uint256 assetsOut = vault.withdraw(100e18);

        assertEq(assetsOut, 100e6, "assets returned");
        assertEq(vault.balanceOf(alice), 0, "shares burned");
        assertEq(vault.totalSupply(), 0, "no shares outstanding");
        assertEq(vault.totalSupplied(), 0, "totalSupplied zeroed");
        assertEq(usdc.balanceOf(alice), aliceUsdcBefore, "alice fully refunded");
    }

    function test_withdraw_blockedWhenWouldGoUnderwater() public {
        vm.prank(alice);
        vault.deposit(100e6);

        vm.prank(alice);
        vault.borrow(50e6); // safe at 50% LTV

        // Burning most of her shares would leave her debt far above the
        // remaining collateral — must revert with WouldBeLiquidatable.
        vm.prank(alice);
        vm.expectRevert(MiniLendingVault.WouldBeLiquidatable.selector);
        vault.withdraw(90e18);
    }

    // ════════════════════════════════════════════════════════════════════
    //
    //  BONUS TESTS — write these yourself.
    //
    //  The starter suite above covers happy-path borrow/withdraw and the
    //  obvious reverts. The interesting behavior of this vault — health
    //  factor crossing 1e18 and the liquidation flow (including bad debt) —
    //  only shows up when you put the system into a stressed state.
    //
    //  IMPORTANT: there is no external "oracle" or "crash the price" lever
    //  in this contract. The share price is `totalSupplied / totalSupply()`,
    //  and the ONLY thing that moves it is borrowing (which removes USDC
    //  from totalSupplied). This vault is reflexive: a borrow near MAX_LTV
    //  reduces the borrower's own collateral value and can leave them
    //  instantly liquidatable. That's the lever you use to construct these
    //  tests — there is no other.
    //
    //  Tests to add (each one counts toward grading):
    //
    //    1. test_healthFactor_belowOne_afterReflexiveBorrow
    //         Deposit, then borrow aggressively (at or very near MAX_LTV).
    //         Assert vault.getHealthFactor(alice) < 1e18.
    //
    //    2. test_liquidate_revertsWhenHealthy
    //         Alice deposits and borrows conservatively (e.g. 50% LTV).
    //         Bob calls liquidate(alice) → expect NotLiquidatable.
    //
    //    3. test_liquidate_happyPath
    //         Put alice underwater (see #1), have bob call liquidate(alice).
    //         Assert: alice.debt == 0, bob holds alice's shares,
    //                 totalSupplied increased by the repaid debt,
    //                 Liquidated event emitted with correct args.
    //
    //    4. test_liquidate_badDebt
    //         The reflexive crash can leave alice's shares worth LESS in
    //         USDC than her debt. Construct that state and assert your
    //         contract's chosen behavior (see the Task 4 comment in
    //         MiniLendingVault.sol — you picked one of three options;
    //         your test should pin it down).
    //
    // ════════════════════════════════════════════════════════════════════
}
