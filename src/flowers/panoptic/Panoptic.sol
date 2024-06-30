// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Hive} from "../../Hive.sol";
import {ERC20} from "../../tokens/ERC20.sol";
import {Flower} from "../Flower.sol";
import {IPanoptic} from "./IPanoptic.sol";

/// @title Panoptic Flower
/// @author Honeycomb Finance
/// @author Jared Borders
contract Panoptic is Flower {

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice mapping of beekeepers to Bees provided for pollination
    mapping(address beekeeper => uint256 bees) public pollen;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(Hive _hive) Flower(_hive, _hive.asset()) {
        BEE.approve(address(HIVE), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                               POLLINATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Provide Bees to the Flower for pollination
    /// @dev Bees provided capitalize yield bearing position
    /// @dev Throws if the Hive is not the caller
    /// @param _for beekeeper whom the Flower associates the resulting position
    /// @param _with amount of Bees to provide for pollination
    function pollinate(
        address _for,
        uint256 _with
    )
        external
        override
        onlyOwner
    {
        BEE.transferFrom(address(HIVE), address(this), _with);
        pollen[_for] += _with;
    }

    /*//////////////////////////////////////////////////////////////
                                HARVEST
    //////////////////////////////////////////////////////////////*/

    /// @notice Conclude pollination and withdraw from the Flower
    /// @dev Throws if the Hive is not the caller
    /// @param _for beekeeper whom the account is associated with by the Flower
    /// @return harvested amount
    function harvest(address _for)
        external
        override
        onlyOwner
        returns (uint256 harvested)
    {
        harvested = pollen[_for];
        pollen[_for] = 0;
        HIVE.deposit(harvested, _for);
    }

}
