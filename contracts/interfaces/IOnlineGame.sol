// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 *  Notify to game
 */
interface IOnlineGame {

    event GameWrite( uint gameId , uint scene , uint item , address player , bytes32 rv) ;

    // check game contract is availabl.
    function test() external returns( bool ) ;

    // Receive proxy's message 
    function notify( uint item , address player , bytes32 rv ) external returns ( bool ) ;

    function play(
        uint256 itemId,
        bytes32 hv,
        uint256 deadline,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) external returns (address player , bytes32 rv);

}