// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Hive} from "../../Hive.sol";
import {ERC20} from "../../tokens/ERC20.sol";
import {Flower} from "../Flower.sol";
import {ISynthetix} from "./ISynthetix.sol";

/// @title Synthetix Flower
/// @author Apiary
/// @author Jared Borders
contract Synthetix is Flower {

    uint128 public constant sUSDC_MARKET_ID = 1;
    uint256 public constant LEVERAGE = 1;

    ISynthetix public immutable SYNTHETIX_CORE;
    ISynthetix public immutable SYNTHETIX_SPOT_MARKET;
    uint128 public immutable PREFERRED_POOL_ID;
    ERC20 public immutable sUSDC;

    mapping(address => uint128) public protocolAccounts;

    constructor(address _core, Hive _hive) Flower(_hive, _hive.asset()) {
        SYNTHETIX_CORE = ISynthetix(_core);
        SYNTHETIX_SPOT_MARKET =
            ISynthetix(0x18141523403e2595D31b22604AcB8Fc06a4CaA61);
        sUSDC = ERC20(SYNTHETIX_SPOT_MARKET.getSynth(sUSDC_MARKET_ID));

        PREFERRED_POOL_ID = SYNTHETIX_CORE.getPreferredPool();

        BEE.approve(address(SYNTHETIX_CORE), type(uint256).max);
        BEE.approve(address(SYNTHETIX_SPOT_MARKET), type(uint256).max);
        sUSDC.approve(address(SYNTHETIX_CORE), type(uint256).max);
        sUSDC.approve(address(SYNTHETIX_SPOT_MARKET), type(uint256).max);
    }

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
        // transfer Bees to the Flower from the Hive
        BEE.transferFrom(address(HIVE), address(this), _with);

        /// @dev Synthetix expects 18 decimals of precision
        uint256 withD18 = _with * 10 ** (18 - BEE.decimals());

        // wrap the Bess for the Synthetix Core
        SYNTHETIX_SPOT_MARKET.wrap({
            marketId: sUSDC_MARKET_ID,
            wrapAmount: _with,
            minAmountReceived: withD18
        });

        // establish Synthetix account for the beekeeper;
        // if none exists, create one and store it
        uint128 accountId = protocolAccounts[_for] == 0
            ? (protocolAccounts[_for] = SYNTHETIX_CORE.createAccount())
            : protocolAccounts[_for];

        // transfer Bees to the Synthetix Core address as collateral
        SYNTHETIX_CORE.deposit({
            accountId: accountId,
            collateralType: address(sUSDC),
            tokenAmount: withD18
        });

        // delegate collateral to the preferred pool
        /// @custom:meb commenting out the following results
        /// in test_fork_flower_synthetix_pollinate passing
        SYNTHETIX_CORE.delegateCollateral({
            accountId: accountId,
            poolId: PREFERRED_POOL_ID,
            collateralType: address(sUSDC),
            newCollateralAmountD18: withD18,
            leverage: LEVERAGE
        });
    }

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
        /// @dev account preserved despite withdrawal;
        /// future pollination won't require minting a new account
        uint128 accountId = protocolAccounts[_for];

        /// @dev specifying a new collateral amount of zero unwinds the position
        SYNTHETIX_CORE.delegateCollateral({
            accountId: accountId,
            poolId: PREFERRED_POOL_ID,
            collateralType: address(BEE),
            newCollateralAmountD18: 0,
            leverage: 1
        });

        // determine unwound position's collateral amount
        (harvested,,) = SYNTHETIX_CORE.getAccountCollateral({
            accountId: accountId,
            collateralType: address(BEE)
        });

        // withdraw unwound collateral
        SYNTHETIX_CORE.withdraw({
            accountId: accountId,
            collateralType: address(BEE),
            tokenAmount: harvested
        });

        /// @dev use contract balance to determine final amount harvested
        harvested = BEE.balanceOf(address(this));

        // realize the harvest by depositing it into the Hive
        HIVE.deposit(harvested, _for);
    }

    /// @notice Harvest any rewards accumulated
    /// @dev Pollination remains ongoing
    /// @custom:caution calling may result in Synthetix imposed timelocks
    /// @param _for beekeeper whom the account is associated with by the Flower
    /// @return rewards harvested
    function harvestSynthetixRewards(address _for)
        external
        onlyOwner
        returns (uint256 rewards)
    {
        uint128 accountId = protocolAccounts[_for];

        uint256[] memory claimableD18;
        address[] memory distributors;

        // retrieve claimable rewards and associated distributors
        (claimableD18, distributors) = SYNTHETIX_CORE.updateRewards({
            poolId: PREFERRED_POOL_ID,
            collateralType: address(BEE),
            accountId: accountId
        });

        // sanity check; should never fail under normal circumstances
        assert(claimableD18.length == distributors.length);

        // claim rewards from each distributor
        /// @dev rewards are automatically transferred to the Flower
        for (uint256 i = 0; i < claimableD18.length; i++) {
            rewards += SYNTHETIX_CORE.claimRewards({
                accountId: accountId,
                poolId: PREFERRED_POOL_ID,
                collateralType: address(BEE),
                distributor: distributors[i]
            });
        }

        /// @dev use contract balance to determine final amount of rewards
        rewards = BEE.balanceOf(address(this));

        // realize the harvested rewards by depositing it into the Hive
        HIVE.deposit(rewards, _for);
    }

    /// @notice Flower must be ERC-721 compliant
    /// @dev Synthetix accounts are represented as ERC-721 tokens
    /// @return selector to confirm the token transfer
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    )
        external
        pure
        returns (bytes4 selector)
    {
        selector = this.onERC721Received.selector;
    }

}
