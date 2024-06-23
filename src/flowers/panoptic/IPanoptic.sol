// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IPanoptic {

    function stake(uint256) external returns (uint256);
    function unstake(uint256) external returns (uint256);

}
