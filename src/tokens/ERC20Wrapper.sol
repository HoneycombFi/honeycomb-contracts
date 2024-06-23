// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {StringLib} from "../utils/StringLib.sol";
import {ERC20} from "./ERC20.sol";

/// @notice ERC20 Wrapper
/// @author Apiary
contract ERC20Wrapper is ERC20 {

    using StringLib for string;

    error WrapFailed();
    error UnwrapFailed();

    string private constant NAME_PREFIX = "Wrapped ";
    string private constant SYMBOL_PREFIX = "w";

    ERC20 public immutable TOKEN;

    uint256 public totalWrapped;

    constructor(ERC20 _token)
        ERC20(
            (NAME_PREFIX).concat(_token.name()),
            (SYMBOL_PREFIX).concat(_token.symbol()),
            _token.decimals()
        )
    {
        TOKEN = _token;
    }

    function wrap(uint256 _amount) external {
        require(
            TOKEN.transferFrom(msg.sender, address(this), _amount), WrapFailed()
        );

        totalWrapped += _amount;

        _mint(msg.sender, _amount);
    }

    function unwrap(uint256 _amount) external {
        require(balanceOf[msg.sender] >= _amount, UnwrapFailed());

        totalWrapped -= _amount;

        _burn(msg.sender, _amount);

        // cannot underflow; total wrapped is always at least _amount
        TOKEN.transfer(msg.sender, _amount);
    }

}
