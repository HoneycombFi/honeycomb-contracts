// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Hive} from "../Hive.sol";
import {Owned} from "../auth/Owned.sol";
import {ERC20} from "../tokens/ERC20.sol";

/// @title Flower
/// @author Apiary
abstract contract Flower is Owned(msg.sender) {

    Hive public immutable HIVE;
    ERC20 public immutable BEE;

    constructor(Hive _hive, ERC20 _bee) {
        HIVE = _hive;
        BEE = _bee;
    }

    function pollinate(address _for, uint256 _with) external virtual;
    function harvest(address _for)
        external
        virtual
        returns (uint256 harvested);

}
