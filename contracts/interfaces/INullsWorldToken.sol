// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INullsWorldToken {

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint( address player , uint total ) external ;

}