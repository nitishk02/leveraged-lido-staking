// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/LeveragedLidoVault.sol";

contract LeveragedLidoVaultTest is Test {
    LeveragedLidoVault vault;

    address usdc = address(0x1);
    address lido = address(0x2);
    address aave = address(0x3);
    address lender = address(0x4);
    address borrower = address(0x5);
    address uniswapRouter = address(0x6);

    function setUp() public {
        vault = new LeveragedLidoVault(usdc, lido, aave, uniswapRouter);
    }

    function testDelegateBorrowingPower() public {
        vm.prank(lender);
        vault.delegateBorrowingPower(1000 ether, 1.1 ether);

        (uint256 delegatedAmount, , uint256 minHF) = vault.lenders(lender);
        assertEq(delegatedAmount, 1000 ether);
        assertEq(minHF, 1.1 ether);
    }

    function testDepositCollateral() public {
    // Mint USDC to borrower
    deal(usdc, borrower, 2000 * 1e6);

    // Simulate borrower approving the vault
    vm.prank(borrower);
    IERC20(usdc).approve(address(vault), 2000 * 1e6);

    // Borrower deposits collateral
    vm.prank(borrower);
    vault.depositCollateral(1000 * 1e6);

    // Assert that collateral was deposited
    (uint256 collateral, ) = vault.positions(borrower);
    assertEq(collateral, 1000 * 1e6);
}

    function testOpenLeveragedPosition() public {
    // Lender delegates borrowing power
    vm.prank(lender);
    vault.delegateBorrowingPower(5000 * 1e6, 1.1 ether);

    // Mint USDC to borrower
    deal(usdc, borrower, 2000 * 1e6);

    // Simulate borrower approving the vault
    vm.prank(borrower);
    IERC20(usdc).approve(address(vault), 2000 * 1e6);

    // Borrower deposits collateral
    vm.prank(borrower);
    vault.depositCollateral(1000 * 1e6);

    // Borrower opens a leveraged position
    vm.prank(borrower);
    vault.openLeveragedPosition();

    // Assert that the borrowed amount is correct
    (uint256 collateral, uint256 borrowedAmount) = vault.positions(borrower);
    assertEq(collateral, 1000 * 1e6);
    assertEq(borrowedAmount, 5000 * 1e6);
}

}
