// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Owned} from "./auth/Owned.sol";
import {ERC20} from "./tokens/ERC20.sol";
import {ERC4626} from "./tokens/ERC4626.sol";

/// @title BasedVault
/// @notice ERC4626 Vault Implementation for Aggregating and Distributing Yield
contract BasedVault is ERC4626, Owned {

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _owner,
        ERC20 _underlying
    )
        Owned(_owner)
        ERC4626(_underlying, "Based Vault Share", "BVS")
    {}

    /*//////////////////////////////////////////////////////////////
                          STRATEGY MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    event StrategyAdded(bytes32 indexed name);
    event StrategyRemoved(bytes32 indexed name);

    struct Strategy {
        bytes32 name;
        address[] targets;
        bytes[] data;
    }

    /// @notice Record of all strategies by name
    mapping(bytes32 name => Strategy) public strategies;

    /// @notice Owner adds a new yield bearing strategy
    /// @param _name The name of the strategy to add
    /// @param _targets The addresses of the contracts to call
    /// @param _data The data to pass to the contracts
    function addStrategy(
        bytes32 _name,
        address[] calldata _targets,
        bytes[] calldata _data
    )
        external
        onlyOwner
    {
        strategies[_name] = Strategy(_name, _targets, _data);
        emit StrategyAdded(_name);
    }

    /// @notice Owner removes a yield bearing strategy
    /// @param _name The name of the strategy to remove
    function removeStrategy(bytes32 _name) external onlyOwner {
        delete strategies[_name];
        emit StrategyRemoved(_name);
    }

    /*//////////////////////////////////////////////////////////////
                                 YEILD
    //////////////////////////////////////////////////////////////*/

    /// @custom:todo Implement LP:Strategy yield logic

    /// @notice LP selects yield bearing strategy
    /// @param _name The name of the strategy to select
    function selectStrategy(bytes32 _name) external view {
        /// @custom:todo
    }

    /// @notice LP unselects yield bearing strategy
    /// @param _name The name of the strategy to unselect
    function unselectStrategy(bytes32 _name) external view {
        /// @custom:todo
    }

}
