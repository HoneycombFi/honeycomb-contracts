pragma solidity ^0.8.0;

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
