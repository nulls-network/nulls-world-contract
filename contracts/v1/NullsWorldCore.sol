//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IOnlineGame.sol";
import "../interfaces/IOnlineRouter.sol";
import "../utils/Ownable.sol";

contract NullsWorldCore is IOnlineGame, Ownable {

    // random oracle
    address RandomOracle;
    IOnlineRouter OnlineRouter;

    uint256 GameId;
    mapping(uint256 => uint256) Items;      // itemId -> sceneId 
    mapping(uint256 => address ) Scenes ;   // sceneId -> proxyAddress
    bool GameStatus = true;

    // newItem白名单
    mapping(address => bool) newItemWhiteList;

    modifier onlyOwnerOrWhiteList() {
        require(owner() == _msgSender() || newItemWhiteList[_msgSender()] == true, "Ownable: caller is not the owner or white list");
        _;
    }

    constructor(address router) {
        OnlineRouter = IOnlineRouter(router);
    }

    // 设置允许哪些合约地址调用newItem接口
    function addNewItemWhiteList(address user) external onlyOwner {
        newItemWhiteList[user] = true;
    }

    function registerGame(string memory gameName) external onlyOwner {
        GameId = OnlineRouter.registGame(
            address(this),
            gameName,
            address(this)
        );
    }

    function newScene( address addr , string memory name ) external onlyOwnerOrWhiteList returns (uint sceneId) {
        sceneId = OnlineRouter.addScene(GameId, name);
        require( IOnlineGame(addr).test() , "NullsWorldCore/Need to extend IOnlineGame.sol " ) ;
        Scenes[sceneId] = addr ;
    }


    //  合约owner、newItemWhiteList可以调用此接口创建item
    function newItem(
        uint256 sceneId,
        address pubkey
    ) external onlyOwnerOrWhiteList returns (uint256 itemId) {
        itemId = OnlineRouter.addItem(sceneId, pubkey);
        Items[itemId] = sceneId;
    }

    function _checkPublicKey( uint itemId , uint8 v , bytes32 r , bytes32 s , bytes memory privateKey ) internal view {
        ( , address pubkey ) = OnlineRouter.gameinfo(itemId);
        require( pubkey != address(0) , "NullsWorldCore/No public key.") ;
        bytes32 h = keccak256( abi.encode(
            "nulls.world-core",
            privateKey , 
            block.chainid 
        )) ;
        address rec = ecrecover( h , v, r, s ) ;
        require( rec != address(0) , "NullsWorldCore/Wrong signature." ) ;
        require( rec == pubkey , "NullsWorldCore/No match publickey." ) ;
    }

    function publishAndNewItem(
        uint256 sceneId,
        uint256 itemId,
        uint8 v , 
        bytes32 r , 
        bytes32 s ,
        bytes memory privateKey,
        address newPubKey
    ) external onlyOwner returns ( uint newItemId ) {
        // require(Items[itemId] > 0 , "NullsWorldCore/No match item.");
        _checkPublicKey(itemId, v, r, s, privateKey);
        newItemId = OnlineRouter.publistAndNewItem(sceneId, itemId , privateKey, newPubKey);
        Items[ newItemId ] = sceneId ;
    }

    function nonces(uint256 itemId) external view returns (uint256 v) {
        v = OnlineRouter.nonces(itemId);
    }

    function test() external view override returns (bool) {
        return GameStatus;
    }

    function notify(
        uint256 item,
        address player,
        bytes32 rv
    ) external override returns (bool) {
        uint sceneId = Items[item] ;
        address sceneAddr = Scenes[sceneId] ;
        return IOnlineGame(sceneAddr).notify(item, player, rv);
    }

    function play(
        uint256 itemId,
        bytes32 hv,
        uint256 deadline,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) external override returns (address player, bytes32 rv) { 
        (player, rv) =OnlineRouter.play(itemId, hv, deadline, vs, rs, ss);
    }

}
