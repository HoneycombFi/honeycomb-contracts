// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC4626 {
    function deposit(
        uint256 assets,
        address receiver
    ) external returns (uint256 shares);
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);
    function totalAssets() external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
}

interface ISynthetixV3CoreProxy {
    function getPreferredPool() external view returns (uint128);
    function delegateCollateral(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        uint256 newCollateralAmountD18,
        uint256 leverage
    ) external;
    function deposit(
        uint128 accountId,
        address collateralType,
        uint256 tokenAmount
    ) external;
    function withdraw(
        uint128 accountId,
        address collateralType,
        uint256 tokenAmount
    ) external;
    function createAccount() external returns (uint128);
    function claimRewards(
        uint128 accountId,
        uint128 poolId,
        address collateralType,
        address distributor
    ) external returns (uint256);
}

contract BasedVault is ERC20, ERC20Permit, ERC20Votes, Ownable, IERC4626 {
    using SafeERC20 for IERC20;

    IERC20 public immutable asset;
    ISynthetixV3CoreProxy public synthetixCore;
    address public collateralType;
    uint128 public accountId;

    mapping(address => uint256) public rewards;
    uint256 public totalRewards;
    uint128 public preferredPoolId;

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

    constructor(
        IERC20 _asset,
        address _synthetixCore,
        address _collateralType
    ) ERC20("Based Vault Token", "BVT") ERC20Permit("Based Vault Token") {
        asset = _asset;
        synthetixCore = ISynthetixV3CoreProxy(_synthetixCore);
        collateralType = _collateralType;
    }

    function initialize() external onlyOwner {
        require(accountId == 0, "Account already initialized");
        accountId = synthetixCore.createAccount();
        preferredPoolId = synthetixCore.getPreferredPool();
    }

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

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external override returns (uint256 shares) {
        require(accountId != 0, "Account not initialized");
        shares = convertToShares(assets);
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

    function claimRewards() external {
        _claimRewardsInternal();
        _distributeRewards(msg.sender);
    }

    function _claimRewardsInternal() internal {
        uint256 newRewards = synthetixCore.claimRewards(
            accountId,
            preferredPoolId,
            collateralType,
            address(this)
        );
        totalRewards += newRewards;
    }

    function _distributeRewards(address receiver) internal {
        uint256 userShares = balanceOf(receiver);
        uint256 userReward = (totalRewards * userShares) / totalSupply();
        rewards[receiver] += userReward;
        totalRewards -= userReward;

        if (userReward > 0) {
            asset.safeTransfer(receiver, userReward);
            rewards[receiver] = 0;
        }
    }

    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this)) - totalRewards;
    }

    function convertToShares(
        uint256 assets
    ) public view override returns (uint256) {
        uint256 totalSupply = totalSupply();
        return
            totalSupply == 0 ? assets : (assets * totalSupply) / totalAssets();
    }

    function convertToAssets(
        uint256 shares
    ) public view override returns (uint256) {
        uint256 totalSupply = totalSupply();
        return
            totalSupply == 0 ? shares : (shares * totalAssets()) / totalSupply;
    }
}
