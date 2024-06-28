// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.26;

import {Base} from "../../script/configs/Base.sol";
import {Hive} from "../../src/Hive.sol";
import {Synthetix} from "../../src/flowers/synthetix/Synthetix.sol";
import {ERC20} from "../../src/tokens/ERC20.sol";

import {SynthetixErrors} from "../utils/errors/SynthetixErrors.sol";
import {Test} from "forge-std/Test.sol";

contract SynthetixTest is Test, Base, SynthetixErrors {

    uint256 fork;

    Hive hive;
    Synthetix flower;
    ERC20 usdc;

    function setUp() public {
        string memory rpc = vm.envString("BASE_RPC_URL");
        fork = vm.createFork(rpc);
        vm.selectFork(fork);
        vm.rollFork(16_319_000);

        hive = new Hive(USDC);
        usdc = hive.asset();
        flower = new Synthetix(SYNTHETIX_CORE, SYNTHETIX_SPOT_MARKET, hive);
        flower.transferOwnership(address(hive));
        hive.addFlower(address(flower));
    }

    function test_fork_mint_usdc() public {
        deal(address(usdc), address(this), 1000 ether);
        assertEq(usdc.balanceOf(address(this)), 1000 ether);
    }

    function test_fork_flower_synthetix_pollinate() public {
        uint256 minDelagationAmount = 100 ether;
        deal(address(usdc), address(this), 1000 ether);
        usdc.approve(address(hive), type(uint256).max);
        uint256 scaledAmount =
            minDelagationAmount / (10 ** (18 - usdc.decimals()));
        hive.deposit({assets: scaledAmount, receiver: address(this)});
        hive.pollinate({_flower: address(flower)});
    }

    function test_fork_flower_synthetix_harvest() public {
        vm.roll(block.number - 2 days);
        uint256 minDelagationAmount = 100 ether;
        deal(address(usdc), address(this), 1000 ether);
        usdc.approve(address(hive), type(uint256).max);
        uint256 scaledAmount =
            minDelagationAmount / (10 ** (18 - usdc.decimals()));
        hive.deposit({assets: scaledAmount, receiver: address(this)});
        hive.pollinate({_flower: address(flower)});
        vm.roll(block.timestamp + 2 days);
        //hive.harvest({_flower: address(flower)});
    }

}
