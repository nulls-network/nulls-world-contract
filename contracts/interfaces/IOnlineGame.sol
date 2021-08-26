// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 *  Notify to game
 */
interface IOnlineGame {

    event GameWrite( uint gameId , uint scene , uint item , address player , bytes rv) ;

    // check game contract is availabl.
    function test() external returns( bool ) ;

    // Receive proxy's message 
    function notify( uint item , address player , bytes memory rv ) external returns ( bool ) ;

}