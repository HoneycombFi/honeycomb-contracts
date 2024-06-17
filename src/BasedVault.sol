// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Owned} from "./auth/Owned.sol";
import {ERC20} from "./tokens/ERC20.sol";
import {ERC4626} from "./tokens/ERC4626.sol";

/// @title BasedVault
/// @notice ERC4626 Vault Implementation for Aggregating and Distributing Yield
contract BasedVault is ERC4626, Owned {

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct Initiate {
        address[] targets;
        bytes[] data;
    }

    struct Sync {
        address[] targets;
        bytes[] data;
    }

    struct Unwind {
        address[] targets;
        bytes[] data;
    }

    struct Strategy {
        bytes32 name;
        uint256 genesis;
        uint256 lastSync;
        Initiate initiate;
        Sync sync;
        Unwind unwind;
    }

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    Strategy internal strategy;
    Strategy internal stagedStrategy;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    struct ConstructorParams {
        address owner;
        ERC20 underlying;
        Strategy strategy;
    }

    constructor(ConstructorParams memory _params)
        Owned(_params.owner)
        ERC4626(_params.underlying, "Based Vault Share", "BVS")
    {}

    /*//////////////////////////////////////////////////////////////
                             INTROSPECTION
    //////////////////////////////////////////////////////////////*/

    function getStrategy() external view returns (Strategy memory) {
        return strategy;
    }

    function getStagedStrategy() external view returns (Strategy memory) {
        return stagedStrategy;
    }

    /*//////////////////////////////////////////////////////////////
                              INTERACTIONS
    //////////////////////////////////////////////////////////////*/

    event StrategyInitiated(bytes32 indexed name);
    event StrategySynced(bytes32 indexed name);
    event StrategyUnwound(bytes32 indexed name);

    /// @notice Initiate yield bearing strategy
    function initiate() external onlyOwner {
        _initiate();
    }

    function _initiate() internal {
        _execute({
            _targets: strategy.initiate.targets,
            _data: strategy.initiate.data
        });

        emit StrategyInitiated(strategy.name);
    }

    /// @notice Sync the strategy to harvest yield
    /// @dev Can be called by anyone
    function sync() public {
        strategy.lastSync = block.timestamp;

        _execute({_targets: strategy.sync.targets, _data: strategy.sync.data});

        emit StrategySynced(strategy.name);
    }

    /// @notice Unwind the strategy
    function unwind() external onlyOwner {
        _unwind();
    }

    function _unwind() internal {
        _execute({
            _targets: strategy.unwind.targets,
            _data: strategy.unwind.data
        });

        emit StrategyUnwound(strategy.name);
    }

    /*//////////////////////////////////////////////////////////////
                                 UPDATE
    //////////////////////////////////////////////////////////////*/

    event StrategyStaged(bytes32 indexed name);
    event StrategyCommitted(bytes32 indexed name);

    error CommitFailed();

    function stage(Strategy memory _strategy) external onlyOwner {
        _strategy.genesis = block.timestamp;
        _strategy.lastSync = 0;

        stagedStrategy = _strategy;

        emit StrategyStaged(_strategy.name);
    }

    function commit() external onlyOwner {
        require(
            block.timestamp - stagedStrategy.genesis >= 1 days, CommitFailed()
        );

        delete stagedStrategy;
        strategy = stagedStrategy;

        _initiate();

        emit StrategyCommitted(strategy.name);
    }

    /*//////////////////////////////////////////////////////////////
                                EXECUTE
    //////////////////////////////////////////////////////////////*/

    error ExecutionFailed();

    function _execute(
        address[] memory _targets,
        bytes[] memory _data
    )
        internal
    {
        for (uint256 i = 0; i < _targets.length; i++) {
            (bool success,) = _targets[i].call(_data[i]);
            require(success, ExecutionFailed());
        }
    }

}
