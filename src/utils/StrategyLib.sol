// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

library StrategyLib {

    struct Initiate {
        address[] targets;
        bytes4[] selectors;
    }

    struct Sync {
        address[] targets;
        bytes4[] selectors;
    }

    struct Unwind {
        address[] targets;
        bytes4[] selectors;
    }

    struct Strategy {
        bytes32 name;
        uint256 genesis;
        uint256 lastSync;
        Initiate initiate;
        Sync sync;
        Unwind unwind;
    }

    error ExecutionFailed();

    function _execute(
        address[] memory _targets,
        bytes4[] memory _selectors,
        bytes[] memory _args
    )
        internal
    {
        for (uint256 i = 0; i < _targets.length; i++) {
            (bool success,) =
                _targets[i].call(abi.encodePacked(_selectors[i], _args[i]));

            require(success, ExecutionFailed());
        }
    }

}
