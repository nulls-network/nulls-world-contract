// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface INullsPetToken {
    function mint( address player , uint8 tv ) external returns ( uint tokenId ) ;
}