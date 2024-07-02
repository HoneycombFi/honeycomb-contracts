// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.26;

import {Hive} from "../../src/Hive.sol";
import {Panoptic} from "../../src/flowers/panoptic/Panoptic.sol";
import {ERC20} from "../../src/tokens/ERC20.sol";
import {MockToken} from "../utils/mocks/MockToken.sol";
import {Test} from "forge-std/Test.sol";

contract PanopticTest is Test {

    Hive hive;
    Panoptic flower;
    MockToken token;

    function setUp() public {
        token = new MockToken();
        hive = new Hive(address(token));
        flower = new Panoptic(hive);
        flower.transferOwnership(address(hive));
        hive.addFlower(address(flower));
    }

    function test_flower_panoptic() public {
        // mint tokens to deposit into hive
        token.mint(address(this), 100 ether);

        // approve hive to spend tokens
        token.approve(address(hive), 100 ether);

        // deposit tokens into hive
        hive.deposit(100 ether, address(this));

        // pollinate Panoptic flower
        hive.pollinate(address(flower));

        // check that the flower has been pollinated
        assertEq(flower.pollen(address(this)), 100 ether);
        assertEq(token.balanceOf(address(flower)), 100 ether);

        // harvest Panoptic flower
        hive.harvest(address(flower));

        // check that the flower has been harvested
        assertEq(flower.pollen(address(this)), 0);
        assertEq(token.balanceOf(address(flower)), 0);

        // check harvest token are back in the hive
        assertEq(token.balanceOf(address(hive)), 100 ether);

        // check COMB token balance
        assertEq(hive.balanceOf(address(this)), 100 ether);

        // withdraw tokens from hive
        hive.redeem(hive.balanceOf(address(this)), address(this), address(this));

        // check COMB token balance
        assertEq(hive.balanceOf(address(this)), 0);

        // check that the hive has been emptied
        assertEq(token.balanceOf(address(hive)), 0);

        // check tokens have been returned to the user
        assertEq(token.balanceOf(address(this)), 100 ether);
    }

}
