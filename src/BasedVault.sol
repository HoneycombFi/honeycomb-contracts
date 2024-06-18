// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Owned} from "./auth/Owned.sol";
import {ERC20} from "./tokens/ERC20.sol";
import {ERC4626} from "./tokens/ERC4626.sol";
import {StrategyLib} from "./utils/StrategyLib.sol";

/// @title BasedVault
/// @notice ERC4626 Vault Implementation for Aggregating and Distributing Yield
contract BasedVault is ERC4626, Owned {

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    StrategyLib.Strategy internal strategy;
    StrategyLib.Strategy internal stagedStrategy;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCT
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _owner,
        ERC20 _underlying,
        StrategyLib.Strategy memory _strategy
    )
        Owned(_owner)
        ERC4626(_underlying, "Based Vault Share", "BVS")
    {
        _strategy.genesis = block.timestamp;
        _strategy.lastSync = 0;

        strategy = _strategy;

        _initiate();
    }

    /*//////////////////////////////////////////////////////////////
                               INTROSPECT
    //////////////////////////////////////////////////////////////*/

    function getStrategy()
        external
        view
        returns (StrategyLib.Strategy memory)
    {
        return strategy;
    }

    function getStagedStrategy()
        external
        view
        returns (StrategyLib.Strategy memory)
    {
        return stagedStrategy;
    }

    /*//////////////////////////////////////////////////////////////
                                 HOOKS
    //////////////////////////////////////////////////////////////*/

    function afterDeposit(uint256, uint256) internal override {
        sync();
    }

    function beforeWithdraw(uint256 assets, uint256 shares) internal override {
        unwind(assets, shares);
    }

    /*//////////////////////////////////////////////////////////////
                                INITIATE
    //////////////////////////////////////////////////////////////*/

    event StrategyInitiated(
        bytes32 indexed name, uint256 assets, uint256 shares
    );

    function _initiate() internal {
        /// @custom:todo

        emit StrategyInitiated(strategy.name, totalAssets(), totalSupply);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERACT
    //////////////////////////////////////////////////////////////*/

    event StrategySynced(bytes32 indexed name, uint256 assets, uint256 shares);
    event StrategyUnwound(bytes32 indexed name, uint256 assets, uint256 shares);

    /// @notice Sync the strategy to harvest yield
    /// @dev Can be called by anyone
    function sync() public {
        strategy.lastSync = block.timestamp;

        /// @custom:todo

        emit StrategySynced(strategy.name, totalAssets(), totalSupply);
    }

    function unwind(uint256 _assets, uint256 _shares) public {
        /// @custom:todo

        emit StrategyUnwound(strategy.name, _assets, _shares);
    }

    /*//////////////////////////////////////////////////////////////
                                 UPDATE
    //////////////////////////////////////////////////////////////*/

    event StrategyStaged(bytes32 indexed name);
    event StrategyCommitted(bytes32 indexed name);

    error CommitFailed();

    function stage(StrategyLib.Strategy memory _strategy) external onlyOwner {
        _strategy.genesis = block.timestamp;
        _strategy.lastSync = 0;

        stagedStrategy = _strategy;

        emit StrategyStaged(_strategy.name);
    }

    function commit() external {
        require(
            block.timestamp - stagedStrategy.genesis >= 1 days, CommitFailed()
        );

        delete stagedStrategy;
        strategy = stagedStrategy;

        emit StrategyCommitted(strategy.name);
    }

}
