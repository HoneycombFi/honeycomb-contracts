// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Hive} from "../../src/Hive.sol";
import {Panoptic} from "../../src/flowers/panoptic/Panoptic.sol";
import {ERC20} from "../../src/tokens/ERC20.sol";
import {Base} from "../configs/Base.sol";
import {BaseSepolia} from "../configs/BaseSepolia.sol";
import {Script} from "lib/forge-std/src/Script.sol";

contract DeployPanopticFlower is Script {

    modifier broadcast() {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);
        _;
        vm.stopBroadcast();
    }

    function deploy(address existingHive) public returns (address) {
        Panoptic flower = new Panoptic(Hive(existingHive));

        return address(flower);
    }

}

/// @dev steps to deploy and verify on Base:
/// (1) load the variables in the .env file via `source .env`
/// (2) run `forge script script/flowers/Panoptic.s.sol:DeployPanopticFlowerBase
/// --rpc-url $BASE_RPC_URL --etherscan-api-key $BASESCAN_API_KEY --broadcast
/// --verify -vvvv`
contract DeployPanopticFlowerBase is DeployPanopticFlower, Base {

    function run() public broadcast returns (address panoptic) {
        panoptic = deploy(HIVE);
    }

}

/// @dev steps to deploy and verify on BaseSepolia:
/// (1) load the variables in the .env file via `source .env`
/// (2) run `forge script
/// script/flowers/Panoptic.s.sol:DeployPanopticFlowerBaseSepolia --rpc-url
/// $BASE_SEPOLIA_RPC_URL --etherscan-api-key $BASESCAN_API_KEY --broadcast
/// --verify -vvvv`
contract DeployPanopticFlowerBaseSepolia is
    DeployPanopticFlower,
    BaseSepolia
{

    function run() public broadcast returns (address panoptic) {
        panoptic = deploy(HIVE);
    }

}
