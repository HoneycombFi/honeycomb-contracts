// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Owned} from "./auth/Owned.sol";

import {Flower} from "./flowers/Flower.sol";
import {ERC20} from "./tokens/ERC20.sol";
import {ERC4626} from "./tokens/ERC4626.sol";

/// @title Hive
/// @author Apiary
contract Hive is ERC4626, Owned(msg.sender) {

    error WiltedFlower();

    string public constant NAME = "Bee";
    string public constant SYMBOL = "BEE";

    mapping(address flower => bool) public flowers;

    modifier onlyFlower(address _flower) {
        require(flowers[_flower], WiltedFlower());
        _;
    }

    constructor(address _underlying)
        ERC4626(ERC20(_underlying), NAME, SYMBOL)
    {}

    function pollinate(address _flower) external onlyFlower(_flower) {
        uint256 bees = previewRedeem(maxRedeem(msg.sender));

        redeem(bees, address(this), msg.sender);

        asset.approve(_flower, bees);

        Flower(_flower).pollinate({_for: msg.sender, _with: bees});
    }

    function harvest(address _flower) external onlyFlower(_flower) {
        Flower(_flower).harvest(msg.sender);
    }

}
