// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.26;

import {Hive} from "../../src/Hive.sol";
import {Panoptic} from "../../src/flowers/panoptic/Panoptic.sol";
import {ERC20} from "../../src/tokens/ERC20.sol";
import {Test} from "forge-std/Test.sol";

contract PanopticTest is Test {

    Hive hive;
    Panoptic flower;
    ERC20 usdc;

    function setUp() public {}

    function test_flower_panoptic_pollinate() public {}

    function test_flower_panoptic_harvest() public {}

}
