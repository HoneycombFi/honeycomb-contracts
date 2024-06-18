// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20, StrategyLib} from "../src/BasedVault.sol";
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

    function deploy(
        address _owner,
        ERC20 _underlying,
        StrategyLib.Strategy memory _strategy
    )
        public
        returns (address)
    {
        /// @custom:todo
    }

}

contract DeployLocal is Deploy, Local {

    function run() public broadcast {
        StrategyLib.Strategy memory strategy;
        deploy(OWNER, ERC20(UNDERLYING), strategy);
    }

}

contract DeployBase is Deploy, Base {

    function run() public broadcast {
        StrategyLib.Strategy memory strategy;
        deploy(OWNER, ERC20(UNDERLYING), strategy);
    }

}
