// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/contracts/BasedVault.sol";
import "../src/contracts/mocks/MockERC20.sol";
import "../src/contracts/mocks/MockSynthetixCoreProxy.sol";

contract BasedVaultTest is Test {
    BasedVault basedVault;
    MockERC20 usdc;
    address user;
    address owner;
    address synthetixCore;

    uint256 depositAmount = 1000 * 10 ** 6; // 1000 USDC with 6 decimals

    function setUp() public {
        owner = address(this);
        user = address(0x123);
        usdc = new MockERC20("Mock USDC", "mUSDC", 6);
        synthetixCore = address(new MockSynthetixCoreProxy());

        basedVault = new BasedVault(usdc, synthetixCore, address(usdc));
        basedVault.initialize();

        usdc.mint(user, depositAmount);
    }

    function testDepositAndMintShares() public {
        vm.startPrank(user);
        usdc.approve(address(basedVault), depositAmount);
        uint256 shares = basedVault.deposit(depositAmount, user);
        assertEq(shares, depositAmount);
        assertEq(basedVault.balanceOf(user), depositAmount);
        vm.stopPrank();
    }

    function testClaimRewards() public {
        vm.startPrank(user);
        usdc.approve(address(basedVault), depositAmount);
        basedVault.deposit(depositAmount, user);

        // Simulate reward distribution
        // MockRewardDistributor synthetixCore.claimRewards(depositAmount);

        basedVault.claimRewards();
        uint256 rewards = basedVault.rewards(user);
        assertEq(rewards, depositAmount);
        vm.stopPrank();
    }

    function testWithdrawAndBurnShares() public {
        vm.startPrank(user);
        usdc.approve(address(basedVault), depositAmount);
        basedVault.deposit(depositAmount, user);

        // Simulate reward distribution
        //  MockRewardDistributor synthetixCore.claimRewards(depositAmount);

        uint256 shares = basedVault.balanceOf(user);
        basedVault.withdraw(shares, user, user);
        assertEq(basedVault.balanceOf(user), 0);
        vm.stopPrank();
    }
}
