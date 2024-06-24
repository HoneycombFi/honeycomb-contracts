// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.26;

import {Hive} from "../../src/Hive.sol";
import {Synthetix} from "../../src/flowers/synthetix/Synthetix.sol";
import {ERC20} from "../../src/tokens/ERC20.sol";
import {Test} from "forge-std/Test.sol";

contract SynthetixTest is Test {

    Hive hive;
    Synthetix flower;
    ERC20 usdc;

    function setUp() public {}

    function test_flower_synthetix_pollinate() public {}

    function test_flower_synthetix_harvest() public {}

    function test_flower_synthetix_harvestSynthetixRewards() public {}

}
