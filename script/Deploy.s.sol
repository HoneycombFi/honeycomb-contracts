// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Base} from "./configs/Base.sol";
import {Local} from "./configs/Local.sol";
import {Script} from "lib/forge-std/src/Script.sol";

contract Deploy is Script {

    modifier broadcast() {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        _;
        vm.stopBroadcast();
    }

    function deploy() public returns (address) {
        /// @custom:todo
    }

}

contract DeployLocal is Deploy, Local {

    function run() public broadcast {
        deploy();
    }

}

contract DeployBase is Deploy, Base {

    function run() public broadcast {
        deploy();
    }

}
