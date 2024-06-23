// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.26;

import {Hive} from "../src/Hive.sol";
import {ERC20} from "../src/tokens/ERC20.sol";
import {Test} from "forge-std/Test.sol";

contract HiveTest is Test {

    /// @custom:todo add tests

    Hive hive;
    ERC20 bee;

    function setUp() public {
        bee = new ERC20("USD Coin", "USDC", 6);
        hive = new Hive(address(bee));
    }

    function test_hive_vault_name() public view {
        string memory name = hive.name();
        assertEq(name, "Bee");
    }

    function test_hive_vault_symbol() public view {
        string memory symbol = hive.symbol();
        assertEq(symbol, "BEE");
    }

}
