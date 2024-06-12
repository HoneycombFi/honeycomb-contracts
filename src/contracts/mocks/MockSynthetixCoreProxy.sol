// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockSynthetixCoreProxy {
    uint128 private _accountId;
    uint128 private _preferredPoolId;

    constructor() {
        _accountId = 1;
        _preferredPoolId = 1;
    }

    function getPreferredPool() external view returns (uint128) {
        return _preferredPoolId;
    }

    function delegateCollateral(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        uint256 newCollateralAmountD18,
        uint256 leverage
    ) external {
        // Mock implementation
    }

    function deposit(
        uint128 accountId,
        address collateralType,
        uint256 tokenAmount
    ) external {
        // Mock implementation
    }

    function withdraw(
        uint128 accountId,
        address collateralType,
        uint256 tokenAmount
    ) external {
        // Mock implementation
    }

    function createAccount() external returns (uint128) {
        return _accountId;
    }

    function claimRewards(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        address distributor
    ) external returns (uint256) {
        // Mock implementation
        return 1000 * 10 ** 18; // 1000 tokens as reward
    }
}
