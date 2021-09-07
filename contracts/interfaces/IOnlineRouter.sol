// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IOnlineRouter {

    event NewGame( address game , address mng , uint gameId , string gameName ) ;

    event NewGameScene( uint gameId , uint sceneId , string sceneName , address sender ) ;

    event NewGameItem( uint sceneId , uint itemId , address pubkey , address sender) ;

    event PublishPrivateKey( uint itemId , bytes privateKey , address sender ) ;

    event GameWrite( uint itemId, bytes32 hv , bytes32 rv , address player) ;

    event NewNonce(uint itemId, bytes32 hv, uint256 nonce, address player);

    function registGame( address game , string memory name , address oper ) external returns (uint gameId ) ;

    function addScene( uint gameId , string memory name ) external returns (uint sceneId ) ;

    function addItem( uint sceneId , address pubkey ) external returns ( uint itemId ) ;

    function publistAndNewItem( uint sceneId , uint oldItemId , bytes memory privateKey , address newPubKey ) external returns (uint newItemId ) ;

    function getNonce(uint256 itemId, bytes32 hv, address player) external returns(uint256 nonce);

    function gameinfo(uint256 itemId) external view returns (address gameAddr, address pubkey);

    function play(
        bytes32 hv,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bytes32 rv);
}