// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface INullsRankManager {


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
    
    // 新擂台: itemId、创建擂台的宠物、擂台支付token、初始资金、创建者、倍率、创建时的公钥
    event NewRank(
        uint256 itemId, 
        uint petId, 
        address token, 
        uint initialCapital, 
        address creater, 
        uint8 multiple, 
        address publicKey
    );

    // 擂台状态更新: itemId、挑战者宠物id、休息结束时间、挑战者、擂台奖池余额、random、挑战者输赢、奖池变化值、reuestKey、币种
    event RankUpdate(
        uint256 itemId, 
        uint challengerPetId, 
        uint restEndTime,
        address challenger, 
        uint bonusPool, 
        bytes32 rv, 
        bool isWin, 
        uint value,
        bytes32 requestKey,
        address token
    );

    // 擂台挑战预获取nonce值: itemId、业务hash、nonce、过期时间、用户
    event RankNewNonce(
        uint itemId, 
        uint challengerPetId,
        bytes32 hv, 
        bytes32 requestKey, 
        uint256 deadline, 
        address user
    );

    event RefundPkFee(
        address user,
        uint itemId,
        address token,
        uint amount
    );

    // --- public mapping的view方法

    // return: 宠物上次pk的截止休息时间，当前时间大于此时间的宠物才可进行pk
    function LastChallengeTime(uint petId) external view returns (uint timestamp);
    // ---

    /*
     * 设置普通宠物休息时间
     *
     * 要求: 
     *      - onlyOwner
     */
    function setRestTime(uint generalPetRestTime) external;

    /*
     * 设置转账交易代理合约
     *
     * 要求: 
     *      - onlyOwner
     */
    function setTransferProxy(address proxy) external;

    /*
     * 设置核心代理合约
     *
     * 要求: 
     *      - onlyOwner
     */
    function setProxy(address proxy) external;

    /*
     * 设置宠物token合约
     *
     * 要求: 
     *      - onlyOwner
     */
    function setPetToken(address petToken) external;

    /*
     * 配置支持用于支付pk费用的token
     *
     * 要求: 
     *      - onlyOwner
     */
    function addRankToken(address token, uint minInitialCapital) external;

    function setAfterProccess( address afterAddr ) external;

    /*
     * 获取擂台信息
     *
     */
    function getRankInfo(uint256 rankId) external view returns(Rank memory rank);

    /*
     * 获取休息时间
     *
     */
    function getRestTime() external view returns(uint generalPetRestTime);

    /*
     * 获取当前合约的场景id
     *
     */
    function getSceneId() external view returns(uint sceneId);

    /*
     * 获取pk门票价格
     *
     */
    function getPrice(address token) external view returns(uint price);

    /*
     * 获取nonce值
     *
     */
    function nonces(address player) external view returns (uint256);

    /*
     * 创建擂台
     *
     */
    function createRank(
        uint petId, 
        address token,
        uint8 multiple
    ) external returns(uint256 itemId);

    /*
     * 挑战擂台
     *
     */
    function pk(
        uint256 itemId,
        uint challengerPetId,
        uint256 deadline
    ) external;
}