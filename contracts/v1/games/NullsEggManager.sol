// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../../interfaces/IOnlineGame.sol";
// import "../../interfaces/IOnlineRouter.sol";
import "../../interfaces/INullsEggToken.sol";
import "../../interfaces/INullsPetToken.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/INullsAfterBuyToken.sol";
import "../../utils/Ownable.sol";
import "../../interfaces/INullsWorldCore.sol";
import "../../utils/Counters.sol";

contract NullsEggManager is IOnlineGame, Ownable {
    address EggToken ;
    address PetToken ;
    address Proxy;
    address BuyTokenAfter ;
    uint SceneId;

    mapping( address => BuyToken ) BuyTokens ;  // token -> config

    struct BuyToken {
        uint amount ;
        bool isOk ;
    }

    using Counters for Counters.Counter;

    // 该nonce值用作生成hash
    mapping(address => Counters.Counter) Nonces;

    function _useNonces(address player) internal returns (uint256 current) {
        Counters.Counter storage counter = Nonces[player];
        current = counter.current();
        counter.increment();
    }

    struct DataInfo {
        uint total;
        uint itemId;
        uint256 nonce;
        address player;
        bool isOk;
    }

    mapping( bytes32 => DataInfo) DataInfos;

    address BuyAfterAddress ;   //购买后的处理函数

    bool IsOk = true;

    event NewPet(uint petid, uint batchIndex , uint item , address player , uint v , bytes32 rv ) ;

    event EggNewNonce(uint itemId, bytes32 hv, uint256 nonce, uint256 deadline) ;

    modifier isFromProxy() {
        require(msg.sender == Proxy, "NullsEggManager/Is not from proxy.");
        _;
    }

    function setProxy(address proxy, string memory name) external onlyOwner {
        Proxy = proxy;
        SceneId = INullsWorldCore(Proxy).newScene(address(this), name);
    }

    function getSceneId() external view returns(uint sceneId) {
        return SceneId;
    }

    // 根据币种查询买蛋单价
    function getPrice(address token) external view returns(uint price) {
        BuyToken memory buyToken =  BuyTokens[token];
        require(buyToken.isOk, "NullsEggManager/Unsupported token.");
        price = buyToken.amount;
    }

    function setPetToken( address eggToken , address petToken ) external onlyOwner {
        EggToken = eggToken ;
        PetToken = petToken ;
    }

    function setAfterProccess( address afterAddr ) external onlyOwner {
        BuyTokenAfter = afterAddr ;
    }

    function setBuyToken( address token , uint amount ) external onlyOwner {
        BuyToken memory buyToken = BuyToken({
            amount : amount ,
            isOk : true 
        }) ;
        BuyTokens[ token ] = buyToken ;
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

        IERC20( EggToken ).transferFrom( dataInfo.player, address(this), dataInfo.total );
        // IERC20 egg = IERC20( EggToken ) ;
        for(uint8 i = 0 ; i < dataInfo.total ; i ++ ) {
            _openOne( i , dataInfo.itemId , dataInfo.player , rv ) ;
        }
 
        // isOk标志设置为false
        dataInfo.isOk = false;
        DataInfos[hv] = dataInfo;
        
        return true;
    }

    function _openOne( uint8 index , uint item , address player , bytes32 rv ) internal returns ( uint petid ){
        //random v 
        bytes32 val = keccak256( abi.encode(
            player , 
            item , 
            index , 
            rv 
        )) ;
        uint8 tv = uint8(bytes1(val)) ;
        petid = INullsPetToken( PetToken ).mint( player , tv ) ;

        //emit Open
        emit NewPet(petid, index , item, player, tv , rv);
    }

    // approve -> transferFrom
    function buy( uint total , address token ) external {
        address sender = msg.sender ;
        require( total > 0 , "NullsEggManager/Total is zero.") ;
        //扣款
        BuyToken memory buyToken = BuyTokens[ token ] ;
        require( buyToken.isOk == true , "NullsEggManager/Not allow token." ) ;
        uint amount = total * buyToken.amount ;

        //got token 
        IERC20( token ).transferFrom( sender, address(this) , amount );

        // show buyer the egg .
        INullsEggToken( EggToken ).mint( sender , total ) ; 

        // after proccess 
        if( BuyTokenAfter != address(0) ) {
            //approve to after 
            // IERC20( token ).approve( address(this) , amount );
            INullsAfterBuyToken( BuyTokenAfter ).doAfter(sender, total, token, amount );
        }
    } 

    function superTransfer( address token , address to , uint amount ) external onlyOwner {
        IERC20( token ).transfer( to , amount );
    }

    function openMultiple(
        uint total ,
        uint itemId , 
        uint256 deadline
    ) external {
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
            isOk: true
        });
        emit EggNewNonce(itemId, hv, nonce, deadline);
    }
}
