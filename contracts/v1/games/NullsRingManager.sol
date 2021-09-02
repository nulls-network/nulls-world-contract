// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../../interfaces/IOnlineGame.sol";
import "../../utils/Ownable.sol";
import "../../interfaces/INullsPetToken.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/INullsWorldCore.sol";

contract NullsRingManager is IOnlineGame, Ownable {

    address Proxy = address(0);
    address PetToken = address(0);
    bool IsOk = false;

    // 普通宠物休息时间（秒）
    uint GeneralPetRestTime = 300;
 
    // 支持的token列表
    mapping( address => RingTokenConfig ) RingTokens;

    // 记录上次挑战时间
    // 对于普通宠物: 上次挑战时间
    mapping( uint => uint) public LastChallengeTime;

    struct RingTokenConfig {
        // 最小启动资金
        uint minInitialCapital;
        bool isOk ;
    }

    // 擂台信息
    mapping( uint256 => Ring) public Rings;

    // 记录pet、Item映射关系
    mapping( uint => bool ) PetLocked; // petid -> beating  

    struct Ring {
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

    // 创建擂台，itemId、创建擂台的宠物、擂台支付token、初始资金、创建者、倍率
    event NewRing(uint256 itemId, uint petId, address token, uint initialCapital, address creater, uint8 multiple);

    // 擂台状态更新,itemId、挑战者宠物id、挑战者、擂台奖池余额、random、挑战者输赢、奖池变化值
    event RingUpdate(uint256 itemId, uint challengerPetId, address challenger, uint bonusPool, bytes32 rv, bool isWin , uint value);


    // 设置休息时间
    function setRestTime( uint generalPetRestTime) external onlyOwner {
        GeneralPetRestTime = generalPetRestTime;
    }


    // 获取休息时间配置
    function getRestTime() public view returns(uint generalPetRestTime){
        return GeneralPetRestTime;
    }

    // 添加支持的代币
    function addRingToken( address token, uint minInitialCapital) external onlyOwner {
        RingTokens[ token ] = RingTokenConfig({
            minInitialCapital: minInitialCapital,
            isOk: true
        }) ;
    }

    function setProxy(address proxy) external onlyOwner {
        Proxy = proxy;
        if (PetToken != address(0)) {
            IsOk = true;
        }
    }

    function setPetToken( address petToken ) external onlyOwner {
        PetToken = petToken ;
        if (Proxy != address(0)) {
            IsOk = true;
        }
    }

    // check game contract is availabl.
    function test() external view override returns( bool ) {
        return IsOk;
    }

  
    // 服务端调用此接口创建擂台，在调用接口前，服务端需要判断客户端的签名是否正确
    // 创建擂台,擂台创建时自动创建一个Item
    // 需要预先创建擂台PK场景
    // 返回擂台ID(item ID)
    function createRing(
        address creator,
        uint petId, 
        address token,
        uint8 multiple,
        uint256 sceneId,
        address pubkey ) external onlyOwner returns(uint256 itemId) {

            // 是否在守擂中
            bool isLocked = PetLocked[petId] ;
            require( isLocked == false , "NullsRingManager/The pet is beating.");

            // 检查token是否合法
            require(RingTokens[token].isOk == true, "NullsRingManager/Unsupported token.");
            // 检查倍率是否合法
            require(multiple == 5 || multiple== 10, "NullsRingManager/Unsupported multiple.");

            // 检查petId是否合法
            require(INullsPetToken( PetToken ).ownerOf(petId) == creator, "NullsRingManager/Pet id is illegal");
            require(INullsPetToken( PetToken ).Types(petId) == 0xff, "NullsRingManager/Pets do not have the ability to open the ring");
            uint initialCapital = RingTokens[token].minInitialCapital * multiple;
            // 转出擂台启动资金
            IERC20( token ).transferFrom( creator, address(this) , initialCapital );
            // 创建item
            itemId = INullsWorldCore(Proxy).newItem(sceneId, pubkey);

            // 记录擂台信息
            Rings[itemId] = Ring({
                petId: petId,
                token: token,
                initialCapital: initialCapital,
                ticketAmt : RingTokens[token].minInitialCapital ,
                multiple: multiple,
                creater: creator,
                bonusPool: initialCapital,
                ownerBonus: 0,
                gameOperatorBonus: 0,
                total: 0
            });

            PetLocked[petId] = true ;            
            emit NewRing(itemId, petId, token, initialCapital, creator, multiple);
    }

    function getRewardRatio(uint total) internal pure returns(uint8 ringPool, uint8 ringOwner, uint8 gameOperator) {
        if (total <= 10) {
            ringPool = 6;
            ringOwner = 3;
            gameOperator = 1;
        } else if (total > 10 && total <= 20) {
            ringPool = 7;
            ringOwner = 2;
            gameOperator = 1;
        } else {
            ringPool = 8;
            ringOwner = 1;
            gameOperator = 1;
        }
    }

    function doReward(address player, uint256 itemId, bytes32 rv, uint challengerPetId) internal {
        Ring memory ring = Rings[itemId];
        // 判断擂台奖金池
        require(ring.bonusPool > 0, "NullsRingManager/The ring bonus pool is 0");

        // 计算挑战金(初始资金/倍率)
        uint challengeCapital = ring.ticketAmt;

        // 从挑战者账户扣款
        IERC20( ring.token ).transferFrom( player, address(this) , challengeCapital);

        // 挑战金分成
        (uint8 ringPoolRatio, uint8 ringOwnerRatio, uint8 gameOperatorRatio) = getRewardRatio(ring.total);

        // 给擂台奖金池
        ring.bonusPool += challengeCapital * ringPoolRatio / 10;

        // 给擂台所有者
        ring.ownerBonus += challengeCapital * ringOwnerRatio / 10;

        // 给游戏运营商
        ring.gameOperatorBonus += challengeCapital * gameOperatorRatio / 10;
        

        // 判断挑战结果,1/16的获胜几率
        if (uint8(bytes1(rv)) & 0x0f == 0x0f) {
            // 挑战者获胜
            if (challengeCapital * 10 > ring.bonusPool) {
                // 全部赢走
                
                // 给挑战者转账
                IERC20( ring.token ).transfer( player, ring.bonusPool);
                // 结算擂台所属者奖金
                address ringOwner = INullsPetToken( PetToken ).ownerOf(ring.petId);
                IERC20( ring.token ).transfer( ringOwner, ring.ownerBonus);
                ring.ownerBonus = 0;

                // 结算游戏服务商奖金
                // ring.gameOperatorBonus = 0;
                IERC20( ring.token ).transfer( owner() , ring.gameOperatorBonus); 
                ring.gameOperatorBonus = 0;

                // 解锁守擂宠物
                PetLocked[ring.petId] = false ;

                emit RingUpdate(itemId, challengerPetId, player, 0, rv, true, ring.bonusPool);
                ring.bonusPool = 0;     
            } else {
                // 只能赢走一半
                uint poolBalance = ring.bonusPool / 2;
                // 给挑战者转账
                IERC20( ring.token ).transfer( player, poolBalance );
                emit RingUpdate(itemId, challengerPetId, player, poolBalance , rv, true , poolBalance );
                ring.bonusPool = poolBalance;
            }
        } else {
            // 庄家获胜
            emit RingUpdate(itemId, challengerPetId, player, ring.bonusPool, rv, false , challengeCapital * ringPoolRatio / 10);
        }

        Rings[itemId] = ring;
        
    }

    // 发起PK
    function pk(
        uint256 itemId,
        uint challengerPetId,
        bytes32 hv ,
        uint256 deadline,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) external {

        // 是否在休息中
        require(block.timestamp > LastChallengeTime[challengerPetId] , "NullsRingManager/Pets at rest");

        // 记录时间
        LastChallengeTime[challengerPetId] = block.timestamp + GeneralPetRestTime;

        (address player, bytes32 rv) = IOnlineGame(Proxy).play(itemId, hv, deadline, vs, rs, ss);

        // 判断宠物所属权
        require(INullsPetToken( PetToken ).ownerOf(challengerPetId) == player, "NullsRingManager/Pet id is illegal");
 
        doReward(player, itemId, rv, challengerPetId);
    }

    // Receive proxy's message 
    function notify( uint item , address player , bytes32 rv ) external override returns ( bool ) {
        return true;
    }

    function play(
        uint256 itemId,
        bytes32 hv,
        uint256 deadline,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) public override returns (address player , bytes32 rv) {
        // 计算随机数
    }
}