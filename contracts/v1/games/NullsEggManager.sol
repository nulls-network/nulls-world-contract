// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../../interfaces/IOnlineGame.sol";
// import "../../interfaces/IOnlineRouter.sol";
import "../../interfaces/INullsEggToken.sol";
import "../../interfaces/INullsPetToken.sol";
import "../../interfaces/IERC20.sol";
import "./INullsAfterBuyToken.sol";
import "../../utils/Ownable.sol";

contract NullsEggManager is IOnlineGame, Ownable {
    address EggToken ;
    address PetToken ;
    address Proxy;
    address BuyTokenAfter ;

    mapping( address => BuyToken ) BuyTokens ;  // token -> config

    struct BuyToken {
        uint amount ;
        bool isOk ;
    }

    address BuyAfterAddress ;   //购买后的处理函数

    bool IsOk = false;

    event NewPet(uint petid, uint batchIndex , uint item , address player , uint v , bytes32 rv ) ;

    modifier isFromProxy() {
        require(msg.sender == Proxy, "NullsOpenEggV1/Is not from proxy.");
        _;
    }

    function setProxy(address proxy) external onlyOwner {
        Proxy = proxy;
        IsOk = true;
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

    function notify(
        uint256 item,
        address player,
        bytes32 rv
    ) external override isFromProxy returns (bool) {
        // IERC20( EggToken ).transferFrom( player , address(this), total );
        // IERC20 egg = IERC20( EggToken ) ;
        // // 开蛋逻辑
        // uint total = egg.balanceOf( address(this) ) ;
        // if( total > 20 ) {
        //     total = 20 ;
        // }

        // for(uint8 i = 0 ; i < total ; i ++ ) {
        //     _openOne( i , item , player , rv ) ;
        // }

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
            IERC20( token ).approve( address(this) , amount );
            INullsAfterBuyToken( BuyTokenAfter ).doAfter( total, token, amount );
        }
    } 

    function superTransfer( address token , address to , uint amount ) external onlyOwner {
        IERC20( token ).transfer( to , amount );
    }

    function openMultiple(
        uint total ,
        uint itemId , 
        bytes32 hv ,        // 原始数据签名
        uint256 deadline,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) external {
        require( total > 0 && total <=20 , "NullsEggManager/Use 1-20 at a time.");
        // address player = ecrecover(hash, v, r, s)
        // got egg token from player 
        
        // check sign ..
        // (Proxy).play(itemId, hv, deadline, vs, rs, ss);
        (address player,bytes32 rv) = IOnlineGame(Proxy).play(itemId, hv, deadline, vs, rs, ss);

        IERC20( EggToken ).transferFrom( player, address(this), total );
        // IERC20 egg = IERC20( EggToken ) ;
        for(uint8 i = 0 ; i < total ; i ++ ) {
            _openOne( i , itemId , player , rv ) ;
        }
    }

    function play(
        uint256 itemId,
        bytes32 hv,
        uint256 deadline,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) external override returns (address player , bytes32 rv){

    }
}
