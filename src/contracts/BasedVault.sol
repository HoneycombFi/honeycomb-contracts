// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IERC4626.sol";
import "./interfaces/ISynthetixV3CoreProxy.sol";

/**
 * @title BasedVault
 * @notice A ERC-4626 vault built on top of the Synthetix V3 protocol used to manage LP positions and rewards.
 */
contract BasedVault is ERC20, ERC20Permit, IERC4626 {
    using SafeERC20 for IERC20;

    IERC20 public immutable asset;
    ISynthetixV3CoreProxy public synthetixCore;

    address public collateralType;
    uint128 public accountId;
    uint128 public preferredPoolId;
    uint256 public totalRewards;
    mapping(address => uint256) public rewards;

    event Deposit(
        address indexed sender,
        address indexed receiver,
        uint256 assets,
        uint256 shares
    );
    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @notice Constructs the BasedVault contract.
     * @param _asset The underlying asset managed by the vault.
     * @param _synthetixCore The address of the Synthetix V3 Core Proxy contract.
     * @param _collateralType The address of the collateral type (e.g., WETH).
     */
    constructor(
        IERC20 _asset,
        address _synthetixCore,
        address _collateralType
    ) ERC20("Based Vault Token", "BVT") ERC20Permit("Based Vault Token") {
        asset = _asset;
        synthetixCore = ISynthetixV3CoreProxy(_synthetixCore);
        collateralType = _collateralType;
    }

    /**
     * @notice Initializes the Synthetix V3 account. Can only be called once.
     */
    function initialize() external {
        require(accountId == 0, "Account already initialized");
        accountId = synthetixCore.createAccount();
        preferredPoolId = synthetixCore.getPreferredPool();
    }

    /**
     * @notice Deposits assets into the vault and mints shares to the receiver.
     * @param assets The amount of assets to deposit.
     * @param receiver The address that will receive the shares.
     * @return shares The amount of shares minted.
     */
    function deposit(
        uint256 assets,
        address receiver
    ) external override returns (uint256 shares) {
        require(accountId != 0, "Account not initialized");
        shares = convertToShares(assets);
        asset.safeTransferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        // Deposit collateral into Synthetix V3
        synthetixCore.deposit(accountId, collateralType, assets);

        // Delegate collateral to the preferred pool
        synthetixCore.delegateCollateral(
            accountId,
            preferredPoolId,
            collateralType,
            assets,
            1
        ); // Assuming leverage = 1

        emit Deposit(msg.sender, receiver, assets, shares);

        return shares;
    }

    /**
     * @notice Mints exactly shares Vault shares to receiver by depositing assets of underlying tokens.
     * @param shares The amount of shares to mint.
     * @param receiver The address that will receive the shares.
     * @return assets The amount of assets deposited.
     */
    function mint(
        uint256 shares,
        address receiver
    ) external returns (uint256 assets) {
        require(accountId != 0, "Account not initialized");
        assets = convertToAssets(shares);
        asset.safeTransferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        // Deposit collateral into Synthetix V3
        synthetixCore.deposit(accountId, collateralType, assets);

        // Delegate collateral to the preferred pool
        synthetixCore.delegateCollateral(
            accountId,
            preferredPoolId,
            collateralType,
            assets,
            1
        ); // Assuming leverage = 1

        emit Deposit(msg.sender, receiver, assets, shares);

        return assets;
    }

    /**
     * @notice Withdraws assets from the vault by burning shares.
     * @param assets The amount of assets to withdraw.
     * @param receiver The address that will receive the assets.
     * @param owner The address that owns the shares to be burned.
     * @return shares The amount of shares burned.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external override returns (uint256 shares) {
        require(accountId != 0, "Account not initialized");

        shares = convertToShares(assets);

        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        _burn(owner, shares);

        // Claim and distribute rewards before withdrawing
        _claimRewardsInternal();

        // Get the preferred pool ID
        uint128 poolId = synthetixCore.getPreferredPool();

        // Undelegate the shares from the preferred pool
        synthetixCore.delegateCollateral(
            accountId,
            poolId,
            collateralType,
            0,
            1
        ); // Removing all collateral from the pool

        // Withdraw collateral from Synthetix V3
        synthetixCore.withdraw(accountId, collateralType, assets);

        asset.safeTransfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return shares;
    }

    /**
     * @notice Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     * @param shares The amount of shares to redeem.
     * @param receiver The address that will receive the assets.
     * @param owner The address that owns the shares to be burned.
     * @return assets The amount of assets redeemed.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets) {
        require(accountId != 0, "Account not initialized");

        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        _burn(owner, shares);

        assets = convertToAssets(shares);

        // Claim and distribute rewards before redeeming
        _claimRewardsInternal();

        // Get the preferred pool ID
        uint128 poolId = synthetixCore.getPreferredPool();

        // Undelegate the shares from the preferred pool
        synthetixCore.delegateCollateral(
            accountId,
            poolId,
            collateralType,
            0,
            1
        ); // Removing all collateral from the pool

        // Withdraw collateral from Synthetix V3
        synthetixCore.withdraw(accountId, collateralType, assets);

        asset.safeTransfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @notice Claims and distributes rewards to the caller.
     * Burns the user's shares equivalent to the reward value to prevent repeated claims.
     */
    function claimRewards() external {
        _claimRewardsInternal();
        _distributeRewards(msg.sender);
    }

    /**
     * @notice Returns the total amount of the underlying asset that is managed by the vault.
     * @return The total managed assets.
     */
    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this)) - totalRewards;
    }

    /**
     * @notice Converts a given amount of assets to shares.
     * @param assets The amount of assets.
     * @return The equivalent amount of shares.
     */
    function convertToShares(
        uint256 assets
    ) public view override returns (uint256) {
        uint256 totalSupply = totalSupply();
        return
            totalSupply == 0 ? assets : (assets * totalSupply) / totalAssets();
    }

    /**
     * @notice Converts a given amount of shares to assets.
     * @param shares The amount of shares.
     * @return The equivalent amount of assets.
     */
    function convertToAssets(
        uint256 shares
    ) public view override returns (uint256) {
        uint256 totalSupply = totalSupply();
        return
            totalSupply == 0 ? shares : (shares * totalAssets()) / totalSupply;
    }

    /**
     * @notice Claims rewards internally from the Synthetix Core.
     */
    function _claimRewardsInternal() internal {
        uint256 newRewards = synthetixCore.claimRewards(
            accountId,
            preferredPoolId,
            collateralType,
            address(this)
        );
        totalRewards += newRewards;
    }

    /**
     * @notice Distributes rewards to the specified receiver.
     * @param receiver The address to receive the rewards.
     */
    function _distributeRewards(address receiver) internal {
        uint256 userShares = balanceOf(receiver);
        uint256 userReward = (totalRewards * userShares) / totalSupply();

        uint256 newReward;
        if (userReward > rewards[receiver]) {
            // Calculate the new rewards since the last distribution
            newReward = userReward - rewards[receiver];
        } else {
            newReward = 0;
        }

        // Update the total rewards and the user's rewards owed
        rewards[receiver] = userReward;

        if (newReward > 0) {
            totalRewards -= newReward;
            asset.safeTransfer(receiver, newReward);
        }
    }
}
