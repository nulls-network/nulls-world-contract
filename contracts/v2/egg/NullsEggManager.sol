// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../../interfaces/IZKRandomCallback.sol";
import "../../interfaces/INullsEggToken.sol";
import "../../interfaces/INullsPetToken.sol";
import "../../interfaces/INullsAfterBuyEgg.sol";
import "../../interfaces/INullsWorldCore.sol";
import "../../interfaces/ITransferProxy.sol";
import "../../interfaces-external/INullsEggManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "../../interfaces/INullsBigPrizePool.sol";

contract NullsEggManager is INullsEggManager, IZKRandomCallback, Ownable {

    struct BuyToken {
        uint amount ;
        bool isOk ;
    }

    struct DataInfo {
        uint total;
        uint itemId;
        address player;
        bool isOk;
    }


    address EggToken ;
    address PetToken ;
    address Proxy;
    address BuyTokenAfter ;
    address BigPrizePool;
    ITransferProxy TransferProxy;
    uint SceneId;

    uint public GodPetCount;

    mapping( address => BuyToken ) BuyTokens ;

    using Counters for Counters.Counter;

    // 该nonce值用作生成hash
    mapping(address => Counters.Counter) Nonces;

    mapping( bytes32 => DataInfo) DataInfos;

    mapping(bytes32 => bytes32) KeyToHv;

    address BuyAfterAddress ;   //购买后的处理函数

    bool IsOk = true;

    // 达到此数量，必中擂台宠物
    // 为0不开启此功能
    uint16 GodPetProbabilityValue = 0;

    // 必中擂台宠物，当此数值达到GodPetProbabilityValue时，必定开出擂台宠物
    // 每开到一个普通宠物，该数值+1
    // 当开出擂台宠物时，此值清零
    mapping(address => uint16) public GodPetProbability;

    modifier isFromProxy() {
        require(msg.sender == Proxy, "NullsEggManager/Is not from proxy.");
        _;
    }

    function _useNonces(address player) internal returns (uint256 current) {
        Counters.Counter storage counter = Nonces[player];
        current = counter.current();
        counter.increment();
    }

    function setGodPetProbabilityValue(uint16 val) external override onlyOwner {
        GodPetProbabilityValue = val;
    }

    function getGodPetProbabilityValue() external view override onlyOwner returns(uint16 val) {
        val = GodPetProbabilityValue;
    }

    function setProxy(address proxy) external override onlyOwner {
        Proxy = proxy;
        SceneId = INullsWorldCore(Proxy).newScene(address(this));
    }

    function setTransferProxy(address proxy) external override onlyOwner {
        TransferProxy = ITransferProxy(proxy);
    }

    function setBigPrizePool(address addr) external override onlyOwner {
        BigPrizePool = addr;
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

    function notify(uint item , bytes32 key , bytes32 rv) external override isFromProxy returns (bool) {

        bytes32 hv = KeyToHv[key];
        // 获取业务数据
        DataInfo memory dataInfo = DataInfos[hv];

        require(dataInfo.total > 0, "NullsEggManager/The data obtained by HV is null");
        require(item == dataInfo.itemId, "NullsEggManager/Item verification failed");
        // 防止重复消费data
        require(dataInfo.isOk, "NullsEggManager/Do not repeat consumption.");

        // IERC20 egg = IERC20( EggToken ) ;
        for(uint8 i = 0 ; i < dataInfo.total ; i ++ ) {
            _openOne( i , dataInfo.itemId , dataInfo.player , rv, key) ;
        }
 
        // isOk标志设置为false
        dataInfo.isOk = false;
        DataInfos[hv] = dataInfo;
        
        return true;
    }

    function _openOne( uint8 index , uint item , address player , bytes32 rv, bytes32 requestKey) internal returns ( uint petid ){
        //random v 
        bytes32 val = keccak256( abi.encode(
            player , 
            item , 
            index , 
            rv 
        )) ;

        if (GodPetCount < 32) {
            // 开出godPet概率为1/32
            if (uint8(bytes1(val)) >= 248) {
                val |= 0xff00000000000000000000000000000000000000000000000000000000000000;
            }
        }

        if (GodPetProbabilityValue != 0) {
            if (uint8(bytes1(val)) != 0xff) {
                GodPetProbability[player] += 1;
                if (GodPetProbability[player] >= GodPetProbabilityValue) {
                    GodPetProbability[player] = 0;
                    // 发擂台宠物
                    val |= 0xff00000000000000000000000000000000000000000000000000000000000000;
                }
            } else {
                GodPetProbability[player] = 0;
            }
        }
        if (uint8(bytes1(val)) == 0xff) {
            GodPetCount++;
        }
        petid = INullsPetToken( PetToken ).mint( player , val ) ;

        //emit Open
        emit NewPet(petid, index , item, player, val , rv, requestKey);
    }

    function registerItem(address pubkey) external override onlyOwner {
        uint itemId = INullsWorldCore(Proxy).newItem(SceneId, pubkey, 0);

        emit NewEggItem(itemId, pubkey);
    }

    // approve -> transferFrom
    function buy( uint total , address token ) external override {
        address sender = msg.sender ;
        require( total > 0 , "NullsEggManager/Total is zero.") ;
        //扣款
        BuyToken memory buyToken = BuyTokens[ token ] ;
        require( buyToken.isOk == true , "NullsEggManager/Not allow token." ) ;
        uint amount = total * buyToken.amount ;

        uint serviceProviderAmount = amount / 10;
        uint bigPrizePoolAmount = amount - serviceProviderAmount;

        // transfer to service provider
        TransferProxy.erc20TransferFrom(token, sender, owner(), serviceProviderAmount);

        // transfer to big prize pool
        TransferProxy.erc20TransferFrom(token, sender, BigPrizePool, bigPrizePoolAmount);
        // // transfer to big prize pool
        INullsBigPrizePool(BigPrizePool).transferIn();

        INullsEggToken( EggToken ).mint( sender , total ) ; 

        // after proccess 
        if( BuyTokenAfter != address(0) ) {
            //approve to after 
            // IERC20( token ).approve( address(this) , amount );
            INullsAfterBuyEgg( BuyTokenAfter ).doAfter(sender, total, token, amount );
        }
        emit BuyEgg(sender, total, amount, token);
    } 

    function openMultiple(
        uint total ,
        uint itemId , 
        uint256 deadline
    ) external override {
        require( total > 0 && total <=20 , "NullsEggManager/Use 1-20 at a time.");

        require(block.timestamp <= deadline, "NullsEggManager: expired deadline");
    
        TransferProxy.erc20TransferFrom(EggToken, msg.sender, address(this), total);

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
        bytes32 requestKey = INullsWorldCore(Proxy).getNonce(itemId, hv);

        KeyToHv[requestKey] = hv; 

        // 存储
        DataInfos[hv] = DataInfo({
            total: total,
            itemId: itemId,
            player: msg.sender,
            isOk: true
        });
        emit EggNewNonce(itemId, hv, requestKey, deadline);
        emit OpenEggBefore(msg.sender, total);
    }
}
