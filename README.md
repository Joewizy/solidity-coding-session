# DefiLords — Blockchain Engineer Coding Test

Welcome, and thanks for taking the time. This is a focused Solidity exercise designed to take **90 minutes**.

It's a single file. There's a Foundry harness provided if you want it, but you can do the whole thing in Remix and never touch a CLI.

---

## What we expect

- **Time:** 90 minutes from "start" to submission. Stop the recording when the time is up, regardless of completion.
- **Recording:** record your screen for the duration of the exercise (Loom, OBS, QuickTime — your choice). Submit the recording with your solution.
- **Environment:** Remix is fine. Any editor + Solidity ^0.8.20 + OpenZeppelin imports will work. The Foundry harness in this repo is provided as a convenience.
- **AI tooling:** declare on camera at the start whether you intend to use Copilot, Cursor, ChatGPT, or similar. We do not forbid it, but solutions that show *understanding* will score higher than solutions that show *autocomplete*.
- **Communication:** think out loud. We grade your reasoning at least as much as your final code.

---

## What to submit

1. The completed `src/MiniLendingVault.sol` file.
2. Your screen recording.
3. A short note (3–5 sentences) at the top of `MiniLendingVault.sol` describing the trade-offs you made — especially for the bad-debt edge case in Task 4.

---

## The exercise

You are given the scaffold `src/MiniLendingVault.sol`. It is a simplified lending vault:

- Users deposit USDC and receive ERC-4626-style vault shares.
- Users can borrow USDC against their own shares as collateral, up to a 75% LTV.
- If a user's health factor drops below `1e18`, anyone may liquidate them.

The scaffold is fully commented. **Five functions are marked `TODO`. Implement them:**


| Task | Function                        | What you're doing                                                                                                          |
| ---- | ------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| 1    | `deposit(uint256 assets)`       | Pull USDC, mint shares ERC-4626 style. Handle the first-deposit case correctly.                                            |
| 2    | `borrow(uint256 amount)`        | Enforce the 75% LTV check on cumulative debt, transfer USDC out, update state.                                             |
| 3    | `getHealthFactor(address user)` | Return the scaled health factor with the correct edge cases.                                                               |
| 4    | `liquidate(address user)`       | Allow liquidation when HF < 1e18, transfer debt + seize shares, **handle the bad-debt edge case and explain your choice**. |
| 5    | `withdraw(uint256 shares)`      | Burn shares, return USDC, **revert if the burn would drop the caller's HF below 1e18**.                                    |


You may add helper functions, internal state, events, errors, or imports as you see fit. You may reorganize existing code if you have a reason.

---

## Notes on the scaffold

- **Decimals.** USDC has 6 decimals. The share token (this contract) has 18 decimals. You must bridge that gap in `deposit` and in `sharePriceUSDC`. Read the helper views before writing math.
- **Share-price helpers are provided** — `sharePriceUSDC()` returns USDC per `1e18` shares, and `collateralValueUSDC(user)` returns USDC for the user's full share balance. You may use them or replace them.
- **Reflexivity is real and intentional.** Read the "Reflexivity" block at the top of `MiniLendingVault.sol`. Borrowing reduces share price, which can leave the borrower instantly liquidatable. Task 4 explicitly grades how you reason about the bad-debt scenario that follows. Do not "fix" the reflexivity by adding an oracle or by isolating supply from borrow accounting.
- **Errors and events are pre-declared** as suggestions. Add more if your implementation needs them.
- **No oracle.** USDC is treated as exactly $1 for this exercise.
- **No interest accrual.** Debt does not grow with time.

---

## How we'll evaluate

1. **Correctness** — do the five tasks behave as specified? Edge cases handled?
2. **Decimal math** — USDC's 6 decimals vs. share's 18 decimals are an easy place to be off by `1e12`. Get it right.
3. **First-deposit handling** in `deposit()` — there's a well-known ERC-4626 gotcha here. Spotting and handling it cleanly is a strong signal.
4. **Cumulative debt check** in `borrow()` — checking only the new `amount` rather than `existing + new` is a common bug; we'll look for it.
5. **Bad-debt reasoning** in `liquidate()` — the comment explaining your choice matters. There are at least three reasonable patterns (revert, liquidator absorbs, socialize across share holders). Any of them is defensible; we want to see you *named the problem and chose deliberately*.
6. **HF guard** in `withdraw()` — a withdrawer with outstanding debt must not be allowed to walk away with collateral that would put their own position below water.
7. **Code hygiene** — `SafeERC20` for token transfers, checks-effects-interactions order, no missing access checks where they matter.
8. **Tests (optional but encouraged)** — starter tests live in `test/MiniLendingVault.t.sol`. They will fail until you implement. Add your own tests to demonstrate edge cases (liquidation happy-path, bad-debt scenario, withdraw HF guard). Tests you write count toward grading.

---

## Common pitfalls (heads-up — these are not hints to skip)

- A naïve `sharesMinted = assets` on the first deposit ignores the 6→18 decimal bridge and will break math everywhere downstream.
- A naïve `collateral * MAX_LTV_BPS >= amount * BPS_DENOMINATOR` check in `borrow()` ignores existing debt. Subsequent borrows will silently exceed LTV.
- Dividing by zero in `getHealthFactor()` for a user with no debt — make sure the zero-debt return path is the first thing you check.
- In `liquidate()`, forgetting that the user might own shares the contract no longer fully backs (bad debt) — silently letting `transfer` fail or succeed with bad accounting is worse than reverting.
- In `withdraw()`, doing the burn *before* the HF check is fine if you check the post-burn state correctly; doing it *after* without re-reading state will be wrong.

---

## Running the Foundry harness (optional)

If you prefer Foundry over Remix:

```bash
forge build           # compile
forge test            # run starter tests
forge test -vv        # with logs
```

---

## Questions during the exercise

If a requirement is genuinely ambiguous, **make a reasonable assumption, write it down in a code comment, and continue.** Do not block on clarification — the way you handle ambiguity is itself part of the signal.

If you finish early, use the remaining time to:

- Add more inline tests.
- Document the trade-offs in your top-of-file note.
- Identify one improvement you would make if this were production code (write it as a comment, no need to implement).

---

## After the test

Submit your solution + recording to the email address provided in your invitation. We aim to respond within 48 hours either way.

Good luck.