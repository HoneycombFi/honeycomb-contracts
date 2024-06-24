// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.26;

import {Hive} from "../src/Hive.sol";
import {ERC20} from "../src/tokens/ERC20.sol";
import {MockFlower} from "./utils/mocks/MockFlower.sol";
import {MockProtocol} from "./utils/mocks/MockProtocol.sol";
import {MockToken} from "./utils/mocks/MockToken.sol";
import {Test} from "forge-std/Test.sol";

contract HiveTest is Test {

    Hive hive;
    MockToken token;
    MockProtocol protocol;
    MockFlower flower;

    function setUp() public {
        token = new MockToken();
        protocol = new MockProtocol();
        hive = new Hive(address(token));
        flower = new MockFlower(address(protocol), hive);
    }

    function test_hive_owner() public view {
        assertEq(hive.owner(), address(this));
    }

    function test_hive_vault_share_name() public view {
        assertEq(hive.NAME(), "Bee");
    }

    function test_hive_vault_share_symbol() public view {
        assertEq(hive.SYMBOL(), "BEE");
    }

    function test_hive_vault_share_decimals() public view {
        assertEq(hive.decimals(), 18);
    }

    function test_hive_vault_share_total_supply() public view {
        assertEq(hive.totalSupply(), 0);
    }

    function test_hive_vault_asset() public view {
        assertEq(address(hive.asset()), address(token));
    }

    function test_hive_vault_total_assets() public view {
        assertEq(hive.totalAssets(), 0);
    }

    function test_hive_add_flower(address someFlower) public {
        hive.addFlower(someFlower);
        assertTrue(hive.flowers(someFlower));
    }

    function test_hive_add_flower_only_owner(
        address someCaller,
        address someFlower
    )
        public
    {
        vm.assume(someCaller != hive.owner());
        vm.prank(someCaller);
        vm.expectRevert();
        hive.addFlower(someFlower);
    }

    function test_hive_remove_flower(address someFlower) public {
        hive.addFlower(someFlower);
        hive.removeFlower(someFlower);
        assertFalse(hive.flowers(someFlower));
    }

    function test_hive_remove_flower_only_owner(
        address someCaller,
        address someFlower
    )
        public
    {
        vm.assume(someCaller != hive.owner());
        vm.prank(someCaller);
        vm.expectRevert();
        hive.removeFlower(someFlower);
    }

    function test_hive_pollinate_flower() public {
        // mint 100 tokens to the beekeeper
        token.mint(address(this), 100 ether);
        token.approve(address(hive), 100 ether);

        // beekeeper deposits 100 tokens into the hive
        hive.deposit(100 ether, address(this));

        // add flower to the hive
        hive.addFlower(address(flower));

        // pollinate the flower using beekkeeper's tokens
        hive.pollinate(address(flower));

        // check protocol the flower is using staked the tokens
        assertEq(protocol.staked(address(this)), 100 ether);

        // check protocol's token balance
        assertEq(token.balanceOf(address(protocol)), 100 ether);
    }

    function test_hive_harvest_flower(
        address beekeeper,
        uint64 amount,
        uint64 yield
    )
        public
    {
        // assume amount is non-zero
        vm.assume(amount > 0);

        // set hive's owner to the beekeeper for simplicity
        hive.transferOwnership(beekeeper);

        // set caller context to the beekeeper
        vm.startPrank(beekeeper);

        // mint tokens to the beekeeper
        token.mint(beekeeper, amount);
        token.approve(address(hive), amount);

        // beekeeper deposits tokens into the hive
        hive.deposit(amount, beekeeper);

        // add flower to the hive
        hive.addFlower(address(flower));

        // pollinate the flower using beekkeeper's tokens
        hive.pollinate(address(flower));

        // set the protocol's yield
        protocol.setYield(yield);

        // harvest the flower
        hive.harvest(address(flower));

        // establish harvested amount
        uint256 harvested = uint256(amount) + uint256(yield);

        // check harvest was deposited into the hive
        assertEq(hive.totalAssets(), harvested);

        // check hive's token balance
        assertEq(token.balanceOf(address(hive)), harvested);

        // establish how many shares the beekeeper has
        uint256 shares = hive.balanceOf(beekeeper);

        // redeem all shares for tokens
        hive.redeem(shares, beekeeper, beekeeper);

        // check the beekeeper has all tokens
        assertEq(token.balanceOf(beekeeper), harvested);
    }

}
