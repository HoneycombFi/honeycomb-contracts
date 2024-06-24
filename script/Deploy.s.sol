// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Hive} from "../src/Hive.sol";

import {Panoptic} from "../src/flowers/panoptic/Panoptic.sol";
import {Synthetix} from "../src/flowers/synthetix/Synthetix.sol";
import {ERC20} from "../src/tokens/ERC20.sol";
import {Base} from "./configs/Base.sol";
import {BaseSepolia} from "./configs/BaseSepolia.sol";
import {Script} from "lib/forge-std/src/Script.sol";

contract Deploy is Script {

    modifier broadcast() {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        _;
        vm.stopBroadcast();
    }

    function deploy(
        address underlying,
        address synthetix,
        address panoptic
    )
        public
        returns (address)
    {
        Hive hive = new Hive(underlying);

        hive.addFlower(address(new Synthetix(synthetix, hive)));
        hive.addFlower(address(new Panoptic(panoptic, hive)));

        return address(hive);
    }

}

contract DeployBase is Deploy, Base {

    function run() public broadcast returns (address hive) {
        hive = deploy(UNDERLYING, SYNTHETIX, PANOPTIC);
    }

}

contract DeployBaseSepolia is Deploy, BaseSepolia {

    function run() public broadcast returns (address hive) {
        hive = deploy(UNDERLYING, SYNTHETIX, PANOPTIC);
    }

}
