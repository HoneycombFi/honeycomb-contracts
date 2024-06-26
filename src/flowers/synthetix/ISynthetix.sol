// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface ISynthetix {

    /// @notice Mints an account token with an available id to
    /// `ERC2771Context._msgSender()`.
    function createAccount() external returns (uint128 accountId);

    /// @notice Retrieves the unique system preferred pool.
    /// @return poolId The id of the pool that is currently
    /// set as preferred in the system.
    function getPreferredPool() external view returns (uint128 poolId);

    /// @notice Updates an account's delegated collateral amount for the
    /// specified pool and collateral type pair.
    /// @param accountId The id of the account associated with the position that
    /// will be updated.
    /// @param poolId The id of the pool associated with the position.
    /// @param collateralType The address of the collateral used in the
    /// position.
    /// @param newCollateralAmountD18 The new amount of collateral delegated in
    /// the position,
    /// denominated with 18 decimals of precision.
    /// @param leverage The new leverage amount used in the position,
    /// denominated with 18 decimals of precision.
    ///
    /// Requirements:
    ///
    /// - `ERC2771Context._msgSender()` must be the owner of the account, have
    /// the `ADMIN` permission, or have the `DELEGATE` permission.
    /// - If increasing the amount delegated, it must not exceed the available
    /// collateral (`getAccountAvailableCollateral`) associated with the
    /// account.
    /// - If decreasing the amount delegated, the liquidity position must have a
    /// collateralization ratio greater than the target collateralization ratio
    /// for the corresponding collateral type.
    function delegateCollateral(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        uint256 newCollateralAmountD18,
        uint256 leverage
    )
        external;

    /// @notice Deposits `tokenAmount` of collateral of type `collateralType`
    /// into account `accountId`.
    /// @dev Anyone can deposit into anyone's active account without
    /// restriction.
    /// @param accountId The id of the account that is making the deposit.
    /// @param collateralType The address of the token to be deposited.
    /// @param tokenAmount The amount being deposited, denominated in the
    /// token's native decimal representation.
    function deposit(
        uint128 accountId,
        address collateralType,
        uint256 tokenAmount
    )
        external;

    /// @notice Withdraws `tokenAmount` of collateral of type `collateralType`
    /// from account `accountId`.
    /// @param accountId The id of the account that is making the withdrawal.
    /// @param collateralType The address of the token to be withdrawn.
    /// @param tokenAmount The amount being withdrawn, denominated in the
    /// token's native decimal representation.
    ///
    /// Requirements:
    ///
    /// - `ERC2771Context._msgSender()` must be the owner of the account, have
    /// the `ADMIN` permission, or have the `WITHDRAW` permission.
    function withdraw(
        uint128 accountId,
        address collateralType,
        uint256 tokenAmount
    )
        external;

    /// @notice Returns the total values pertaining to account `accountId` for
    /// `collateralType`.
    /// @param accountId The id of the account whose collateral is being
    /// queried.
    /// @param collateralType The address of the collateral type whose amount is
    /// being queried.
    /// @return totalDeposited The total collateral deposited in the account,
    /// denominated with 18 decimals of precision.
    /// @return totalAssigned The amount of collateral in the account that is
    /// delegated to pools, denominated with 18 decimals of precision.
    /// @return totalLocked The amount of collateral in the account that cannot
    /// currently be undelegated from a pool, denominated with 18 decimals of
    /// precision.
    function getAccountCollateral(
        uint128 accountId,
        address collateralType
    )
        external
        view
        returns (
            uint256 totalDeposited,
            uint256 totalAssigned,
            uint256 totalLocked
        );

    /// @notice Allows a user with appropriate permissions to claim rewards
    /// associated with a position.
    /// @param accountId The id of the account that is to claim the rewards.
    /// @param poolId The id of the pool to claim rewards on.
    /// @param collateralType The address of the collateral used in the pool's
    /// rewards.
    /// @param distributor The address of the rewards distributor associated
    /// with the rewards being claimed.
    /// @return amountClaimedD18 The amount of rewards that were available for
    /// the account and thus claimed.
    function claimRewards(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        address distributor
    )
        external
        returns (uint256 amountClaimedD18);

    /// @notice For a given position, return the rewards that can currently be
    /// claimed.
    /// @param poolId The id of the pool being queried.
    /// @param collateralType The address of the collateral used in the pool's
    /// rewards.
    /// @param accountId The id of the account whose available rewards are being
    /// queried.
    /// @return claimableD18 An array of ids of the reward entries that are
    /// claimable by the position.
    /// @return distributors An array with the addresses of the reward
    /// distributors associated with the claimable rewards.
    function updateRewards(
        uint128 poolId,
        address collateralType,
        uint128 accountId
    )
        external
        returns (uint256[] memory claimableD18, address[] memory distributors);

    /// @notice Returns the amount of the collateral associated with the
    /// specified liquidity position.
    /// @dev Call this function using `callStatic` to treat it as a view
    /// function.
    /// @dev collateralAmount is represented as an integer with 18 decimals.
    /// @param accountId The id of the account being queried.
    /// @param poolId The id of the pool in which the account's position is
    /// held.
    /// @param collateralType The address of the collateral used in the queried
    /// position.
    /// @return collateralAmountD18 The amount of collateral used in the
    /// position, denominated with 18 decimals of precision.
    function getPositionCollateral(
        uint128 accountId,
        uint128 poolId,
        address collateralType
    )
        external
        view
        returns (uint256 collateralAmountD18);

    /// @notice returns a human-readable name for a given market
    function name(uint128 marketId) external view returns (string memory);

    /// @notice Get the proxy address of the synth for the provided marketId
    /// @dev Uses associated systems module to retrieve the token address.
    /// @param marketId id of the market
    /// @return synthAddress address of the proxy for the synth
    function getSynth(uint128 marketId)
        external
        view
        returns (address synthAddress);

    struct WrapperFeeData {
        uint256 fixedFees;
        uint256 utilizationFees;
        int256 skewFees;
        int256 wrapperFees;
    }

    /// @notice Wraps the specified amount and returns similar value of synth
    /// minus the fees.
    /// @dev Fees are collected from the user by way of the contract returning
    /// less synth than specified amount of collateral.
    /// @param marketId Id of the market used for the trade.
    /// @param wrapAmount Amount of collateral to wrap.  This amount gets
    /// deposited into the market collateral manager.
    /// @param minAmountReceived The minimum amount of synths the trader is
    /// expected to receive, otherwise the transaction will revert.
    /// @return amountToMint Amount of synth returned to user.
    /// @return fees breakdown of all fees. in this case, only wrapper fees are
    /// returned.
    function wrap(
        uint128 marketId,
        uint256 wrapAmount,
        uint256 minAmountReceived
    )
        external
        returns (uint256 amountToMint, WrapperFeeData memory fees);

    /// @notice Unwraps the synth and returns similar value of collateral minus
    /// the fees.
    /// @dev Transfers the specified synth, collects fees through configured fee
    /// collector, returns collateral minus fees to trader.
    /// @param marketId Id of the market used for the trade.
    /// @param unwrapAmount Amount of synth trader is unwrapping.
    /// @param minAmountReceived The minimum amount of collateral the trader is
    /// expected to receive, otherwise the transaction will revert.
    /// @return returnCollateralAmount Amount of collateral returned.
    /// @return fees breakdown of all fees. in this case, only wrapper fees are
    /// returned.
    function unwrap(
        uint128 marketId,
        uint256 unwrapAmount,
        uint256 minAmountReceived
    )
        external
        returns (uint256 returnCollateralAmount, WrapperFeeData memory fees);

    /// @notice alias for buyExactIn
    /// @param marketId (see buyExactIn)
    /// @param usdAmount (see buyExactIn)
    /// @param minAmountReceived (see buyExactIn)
    /// @param referrer (see buyExactIn)
    /// @return synthAmount (see buyExactIn)
    /// @return fees (see buyExactIn)
    function buy(
        uint128 marketId,
        uint256 usdAmount,
        uint256 minAmountReceived,
        address referrer
    )
        external
        returns (uint256 synthAmount, WrapperFeeData memory fees);

    /// @notice alias for sellExactIn
    /// @param marketId (see sellExactIn)
    /// @param synthAmount (see sellExactIn)
    /// @param minUsdAmount (see sellExactIn)
    /// @param referrer (see sellExactIn)
    /// @return usdAmountReceived (see sellExactIn)
    /// @return fees (see sellExactIn)
    function sell(
        uint128 marketId,
        uint256 synthAmount,
        uint256 minUsdAmount,
        address referrer
    )
        external
        returns (uint256 usdAmountReceived, WrapperFeeData memory fees);

}
