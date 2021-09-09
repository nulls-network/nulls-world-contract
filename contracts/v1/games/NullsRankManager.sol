// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../../interfaces/IOnlineGame.sol";
import "../../utils/Ownable.sol";
import "../../interfaces/INullsPetToken.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/INullsWorldCore.sol";
import "../../utils/Counters.sol";

contract NullsRankManager is IOnlineGame, Ownable {

    using Counters for Counters.Counter;

    address Proxy = address(0);
    address PetToken = address(0);
    bool IsOk = true;
    uint SceneId ;

    // 普通宠物休息时间（秒）
    uint GeneralPetRestTime = 300;

    mapping(address => Counters.Counter) Nonces;
 
    // 支持的token列表
    mapping( address => RankTokenConfig ) RankTokens;

    // 记录上次挑战时间
    // 对于普通宠物: 上次挑战时间
    mapping( uint => uint) public LastChallengeTime;

    struct RankTokenConfig {
        // 最小启动资金
        uint minInitialCapital;
        bool isOk ;
    }

    // 擂台信息
    mapping( uint256 => Rank) public Ranks;

    // 记录pet、Item映射关系
    mapping( uint => bool ) PetLocked; // petid -> beating  

    struct Rank {
        // 开擂台宠物ID
        uint petId;
        // 擂台挑战token类型
        address token;
        uint ticketAmt ;
        // 初始资金
        uint initialCapital;
        // 倍率，5/10
        // 5: 启动资金为配置的最小启动资金
        // 10: 擂台启动资金为最小启动资金*2
        uint8 multiple;
        // 创建者
        address creater;
        // 奖金池，奖金池归零，擂台失效
        uint bonusPool;
        // 创建者奖励
        uint ownerBonus;
        // 游戏运营商奖励
        uint gameOperatorBonus;
        // 擂台被挑战次数
        uint total;
    }

    struct DataInfo {
        uint challengerPetId;
        uint itemId;
        uint256 nonce;
        address player;
        bool isOk;
    }

    mapping( bytes32 => DataInfo) DataInfos;

    // 创建擂台，itemId、创建擂台的宠物、擂台支付token、初始资金、创建者、倍率、创建时的公钥
    event NewRank(uint256 itemId, uint petId, address token, uint initialCapital, address creater, uint8 multiple, address publicKey);

    // 擂台状态更新,itemId、挑战者宠物id、挑战者、擂台奖池余额、random、挑战者输赢、奖池变化值
    event RankUpdate(uint256 itemId, uint challengerPetId, address challenger, uint bonusPool, bytes32 rv, bool isWin , uint value);

    event RankNewNonce(uint itemId, bytes32 hv, uint256 nonce, uint256 deadline) ;

    modifier isFromProxy() {
        require(msg.sender == Proxy, "NullsOpenEggV1/Is not from proxy.");
        _;
    }

    // 设置休息时间
    function setRestTime( uint generalPetRestTime) external onlyOwner {
        GeneralPetRestTime = generalPetRestTime;
    }


    // 获取休息时间配置
    function getRestTime() public view returns(uint generalPetRestTime){
        return GeneralPetRestTime;
    }

    // 添加支持的代币
    function addRankToken( address token, uint minInitialCapital) external onlyOwner {
        RankTokens[ token ] = RankTokenConfig({
            minInitialCapital: minInitialCapital,
            isOk: true
        }) ;
    }

    function setProxy(address proxy, string memory name) external onlyOwner {
        Proxy = proxy;
        SceneId = INullsWorldCore(Proxy).newScene(address(this), name);
    }

    function getSceneId() external view returns(uint sceneId) {
        return SceneId;
    }

    function setPetToken( address petToken ) external onlyOwner {
        PetToken = petToken ;
    }

    // check game contract is availabl.
    function test() external view override returns( bool ) {
        return IsOk;
    }

    function nonces(address player) public view returns (uint256) {
        return Nonces[player].current();
    }

    function _useNonces(address player) internal returns (uint256 current) {
        Counters.Counter storage counter = Nonces[player];
        current = counter.current();
        counter.increment();
    }
  
    function encodePack(
        uint petId, 
        address token,
        uint8 multiple,
        uint256 nonce
    ) internal view returns (bytes32 v) {

        bytes32 t = keccak256(
            abi.encode(
                "nulls.online-play",
                petId,
                token,
                multiple,
                nonce,
                block.chainid
            )
        );
        v = keccak256( abi.encodePacked(
            "\x19Ethereum Signed Message:\n32" , t
        )) ;
    }
    
    // 创建擂台,擂台创建时自动创建一个Item
    // 需要预先创建擂台PK场景
    // 返回擂台ID(item ID)
    function createRank(
        address creator,
        uint petId, 
        address token,
        uint8 multiple,
        uint8 v , 
        bytes32 r , 
        bytes32 s ,
        address pubkey ) external onlyOwner returns(uint256 itemId) {

            require(creator != address(0), "NullsRankManager/Invalid address.");

            require(
                ecrecover(encodePack(petId, token, multiple, _useNonces(creator)), v, r, s) == creator,
                "NullsRankManager/Signature verification failure."
            ); 

            // 是否在守擂中
            bool isLocked = PetLocked[petId] ;
            require( isLocked == false , "NullsRankManager/The pet is beating.");

            // 检查token是否合法
            require(RankTokens[token].isOk == true, "NullsRankManager/Unsupported token.");
            // 检查倍率是否合法
            require(multiple == 5 || multiple== 10, "NullsRankManager/Unsupported multiple.");

            // 检查petId是否合法
            require(INullsPetToken( PetToken ).ownerOf(petId) == creator, "NullsRankManager/Pet id is illegal");
            require(INullsPetToken( PetToken ).Types(petId) == 0xff, "NullsRankManager/Pets do not have the ability to open the Rank");
            uint initialCapital = RankTokens[token].minInitialCapital * multiple;
            // 转出擂台启动资金
            IERC20( token ).transferFrom( creator, address(this) , initialCapital );
            // 创建item
            itemId = INullsWorldCore(Proxy).newItem( SceneId , pubkey );

            // 记录擂台信息
            Ranks[itemId] = Rank({
                petId: petId,
                token: token,
                initialCapital: initialCapital,
                ticketAmt : RankTokens[token].minInitialCapital ,
                multiple: multiple,
                creater: creator,
                bonusPool: initialCapital,
                ownerBonus: 0,
                gameOperatorBonus: 0,
                total: 0
            });

            PetLocked[petId] = true ;            
            emit NewRank(itemId, petId, token, initialCapital, creator, multiple, pubkey);
    }

    function getRewardRatio(uint total) internal pure returns(uint8 RankPool, uint8 RankOwner, uint8 gameOperator) {
        if (total <= 10) {
            RankPool = 6;
            RankOwner = 3;
            gameOperator = 1;
        } else if (total > 10 && total <= 20) {
            RankPool = 7;
            RankOwner = 2;
            gameOperator = 1;
        } else {
            RankPool = 8;
            RankOwner = 1;
            gameOperator = 1;
        }
    }

    function doReward(address player, uint256 itemId, bytes32 rv, uint challengerPetId) internal {
        Rank memory rank = Ranks[itemId];
        // 判断擂台奖金池
        require(rank.bonusPool > 0, "NullsRankManager/The Rank bonus pool is 0");

        // 计算挑战金(初始资金/倍率)
        uint challengeCapital = rank.ticketAmt;

        // 从挑战者账户扣款
        IERC20( rank.token ).transferFrom( player, address(this) , challengeCapital);

        // 挑战金分成
        (uint8 RankPoolRatio, uint8 RankOwnerRatio, uint8 gameOperatorRatio) = getRewardRatio(rank.total);

        // 给擂台奖金池
        rank.bonusPool += challengeCapital * RankPoolRatio / 10;

        // 给擂台所有者
        rank.ownerBonus += challengeCapital * RankOwnerRatio / 10;

        // 给游戏运营商
        rank.gameOperatorBonus += challengeCapital * gameOperatorRatio / 10;
        

        // 判断挑战结果,1/16的获胜几率
        if (uint8(bytes1(rv)) & 0x0f == 0x0f) {
            // 挑战者获胜
            if (challengeCapital * 10 > rank.bonusPool) {
                // 全部赢走
                
                // 给挑战者转账
                IERC20( rank.token ).transfer( player, rank.bonusPool);
                // 结算擂台所属者奖金
                address RankOwner = INullsPetToken( PetToken ).ownerOf(rank.petId);
                IERC20( rank.token ).transfer( RankOwner, rank.ownerBonus);
                rank.ownerBonus = 0;

                // 结算游戏服务商奖金
                // Rank.gameOperatorBonus = 0;
                IERC20( rank.token ).transfer( owner() , rank.gameOperatorBonus); 
                rank.gameOperatorBonus = 0;

                // 解锁守擂宠物
                PetLocked[rank.petId] = false ;

                emit RankUpdate(itemId, challengerPetId, player, 0, rv, true, rank.bonusPool);
                rank.bonusPool = 0;     
            } else {
                // 只能赢走一半
                uint poolBalance = rank.bonusPool / 2;
                // 给挑战者转账
                IERC20( rank.token ).transfer( player, poolBalance );
                emit RankUpdate(itemId, challengerPetId, player, poolBalance , rv, true , poolBalance );
                rank.bonusPool = poolBalance;
            }
        } else {
            // 庄家获胜
            emit RankUpdate(itemId, challengerPetId, player, rank.bonusPool, rv, false , challengeCapital * RankPoolRatio / 10);
        }

        Ranks[itemId] = rank;
        
    }

    // 发起PK
    function pk(
        uint256 itemId,
        uint challengerPetId,
        uint256 deadline
    ) external {

        require(block.timestamp <= deadline, "NullsRankManager: expired deadline");

        // 判断宠物所有权
        require(INullsPetToken( PetToken ).ownerOf(challengerPetId) == msg.sender, "NullsRankManager/Pet id is illegal");

        // 是否在休息中
        require(block.timestamp > LastChallengeTime[challengerPetId] , "NullsRankManager/Pets at rest");

        // 记录时间
        LastChallengeTime[challengerPetId] = block.timestamp + GeneralPetRestTime;

        // 生成hash
        bytes32 hv = keccak256(
            abi.encode(
                "nulls.egg",
                challengerPetId,
                itemId,
                deadline,
                _useNonces(msg.sender),
                block.chainid
            )
        );
        
        // 调用预注册方法
        uint256 nonce = INullsWorldCore(Proxy).getNonce(itemId, hv, msg.sender);
        // 存储数据
        DataInfos[hv] = DataInfo({
            challengerPetId: challengerPetId,
            itemId: itemId,
            nonce: nonce,
            player: msg.sender,
            isOk: true
        });

        emit RankNewNonce(itemId, hv, nonce, deadline) ;
    }

    // Receive proxy's message 
    function notify( uint item , bytes32 hv , bytes32 rv ) external override isFromProxy returns ( bool ) {
        // 获取业务数据
        DataInfo memory dataInfo = DataInfos[hv];
        require(item == dataInfo.itemId, "NullsRankManager/Item verification failed");

        require(dataInfo.player != address(0), "NullsRankManager/The data obtained by HV is null");
        // 防止重复消费data
        require(dataInfo.isOk, "NullsRankManager/Do not repeat consumption.");

        doReward(dataInfo.player, dataInfo.itemId, rv, dataInfo.challengerPetId);
        
        // isOk标志设置为false
        dataInfo.isOk = false;
        DataInfos[hv] = dataInfo;
        return true;
    }
}