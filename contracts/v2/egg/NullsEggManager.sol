// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../../interfaces/IOnlineGame.sol";
import "../../interfaces/INullsEggToken.sol";
import "../../interfaces/INullsPetToken.sol";
import "../../interfaces/INullsAfterBuyToken.sol";
import "../../interfaces/INullsWorldCore.sol";
import "../../interfaces/ITransferProxy.sol";
import "../../interfaces-external/INullsEggManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NullsEggManager is INullsEggManager, IOnlineGame, Ownable {

    struct BuyToken {
        uint amount ;
        bool isOk ;
    }

    struct DataInfo {
        uint total;
        uint itemId;
        uint256 nonce;
        address player;
        bool isOk;
        string uuid;
    }


    address EggToken ;
    address PetToken ;
    address Proxy;
    address BuyTokenAfter ;
    ITransferProxy TransferProxy;
    uint SceneId;

    mapping( address => BuyToken ) BuyTokens ;  // token -> config

    using Counters for Counters.Counter;

    // 该nonce值用作生成hash
    mapping(address => Counters.Counter) Nonces;

    mapping( bytes32 => DataInfo) DataInfos;

    address BuyAfterAddress ;   //购买后的处理函数

    bool IsOk = true;

    modifier isFromProxy() {
        require(msg.sender == Proxy, "NullsEggManager/Is not from proxy.");
        _;
    }

    function _useNonces(address player) internal returns (uint256 current) {
        Counters.Counter storage counter = Nonces[player];
        current = counter.current();
        counter.increment();
    }

    function setProxy(address proxy, string memory name) external override onlyOwner {
        Proxy = proxy;
        SceneId = INullsWorldCore(Proxy).newScene(address(this), name);
    }

    function setTransferProxy(address proxy) external override onlyOwner {
        TransferProxy = ITransferProxy(proxy);
    }

    function setPetTokenAndEggToken( address eggToken , address petToken ) external override onlyOwner {
        EggToken = eggToken ;
        PetToken = petToken ;
    }

    function setAfterProccess( address afterAddr ) external override onlyOwner {
        BuyTokenAfter = afterAddr ;
    }

    function getSceneId() external view override returns(uint sceneId) {
        return SceneId;
    }

    function setBuyToken( address token , uint amount ) external override onlyOwner {
        BuyToken memory buyToken = BuyToken({
            amount : amount ,
            isOk : true 
        }) ;
        BuyTokens[ token ] = buyToken ;
    }

    // 根据币种查询买蛋单价
    function getPrice(address token) external view override returns(uint price) {
        BuyToken memory buyToken =  BuyTokens[token];
        require(buyToken.isOk, "NullsEggManager/Unsupported token.");
        price = buyToken.amount;
    }

    function test() external view override returns (bool) {
        return IsOk;
    }

    function notify(uint item , bytes32 hv , bytes32 rv) external override isFromProxy returns (bool) {

        // 获取业务数据
        DataInfo memory dataInfo = DataInfos[hv];

        require(dataInfo.total > 0, "NullsEggManager/The data obtained by HV is null");
        require(item == dataInfo.itemId, "NullsEggManager/Item verification failed");
        // 防止重复消费data
        require(dataInfo.isOk, "NullsEggManager/Do not repeat consumption.");

        TransferProxy.erc20TransferFrom(EggToken, dataInfo.player, address(this), dataInfo.total);
        // IERC20 egg = IERC20( EggToken ) ;
        for(uint8 i = 0 ; i < dataInfo.total ; i ++ ) {
            _openOne( i , dataInfo.itemId , dataInfo.player , rv, dataInfo.uuid) ;
        }
 
        // isOk标志设置为false
        dataInfo.isOk = false;
        DataInfos[hv] = dataInfo;
        
        return true;
    }

    function _openOne( uint8 index , uint item , address player , bytes32 rv, string memory uuid ) internal returns ( uint petid ){
        //random v 
        bytes32 val = keccak256( abi.encode(
            player , 
            item , 
            index , 
            rv 
        )) ;
        petid = INullsPetToken( PetToken ).mint( player , val ) ;

        //emit Open
        emit NewPet(petid, index , item, player, val , rv, uuid);
    }

    // approve -> transferFrom
    function buy( uint total , address token ) external override {
        address sender = msg.sender ;
        require( total > 0 , "NullsEggManager/Total is zero.") ;
        //扣款
        BuyToken memory buyToken = BuyTokens[ token ] ;
        require( buyToken.isOk == true , "NullsEggManager/Not allow token." ) ;
        uint amount = total * buyToken.amount ;

        //got token 
        TransferProxy.erc20TransferFrom(token, sender, owner(), amount);

        // show buyer the egg .
        INullsEggToken( EggToken ).mint( sender , total ) ; 

        // after proccess 
        if( BuyTokenAfter != address(0) ) {
            //approve to after 
            // IERC20( token ).approve( address(this) , amount );
            INullsAfterBuyToken( BuyTokenAfter ).doAfter(sender, total, token, amount );
        }
    } 

    function openMultiple(
        uint total ,
        uint itemId , 
        uint256 deadline,
        string memory uuid
    ) external override {
        require( total > 0 && total <=20 , "NullsEggManager/Use 1-20 at a time.");

        require(block.timestamp <= deadline, "NullsEggManager: expired deadline");
    
        // 生成hash
        bytes32 hv = keccak256(
            abi.encode(
                "nulls.egg",
                total,
                itemId,
                deadline,
                _useNonces(msg.sender),
                block.chainid
            )
        );
        

        // 调用预注册方法
        uint256 nonce = INullsWorldCore(Proxy).getNonce(itemId, hv, msg.sender);

        // 存储
        DataInfos[hv] = DataInfo({
            total: total,
            itemId: itemId,
            nonce: nonce,
            player: msg.sender,
            isOk: true,
            uuid: uuid
        });
        emit EggNewNonce(itemId, hv, nonce, deadline);
    }
}