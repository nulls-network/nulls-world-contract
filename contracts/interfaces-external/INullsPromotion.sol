// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface INullsPromotion {
    // 奖励记录: 恐龙蛋购买者、奖励获得者、获得token数量、index(0,1,2,3)
    event RewardRecord( address buyer, address target, uint rewardvalue, uint index, address tokenAddr, uint8 decim);
    // 领取记录: 领取者、金额
    event ReceiveReward(address user, uint total);

    // --- public mapping的view方法
    
    // return: 用户购买蛋时，不同级别用户的奖励token的数量，可传参数: 0:自己 1:一级  2:二级 3:三级
    function RewardValue(uint8 grade) external view returns(uint value);

    // return: 某个用户待领取的奖励值
    function UserRewards(address user) external view returns(uint value);
    // ---

    
    /*
     * 活动奖励金额配置
     *
     * 要求: 
     *      - onlyOwner
     */
    function setReward(
        address token, 
        uint total, 
        uint startTime, 
        uint endTime
    ) external;

    /*
     * 基本信息配置
     *
     * 要求: 
     *      - onlyOwner
     */
    function setBaseInfo(
        address inviteAddr,
        address eggAddr
    ) external;

    /*
     * 配置不同级别用户买蛋的奖励数量
     *
     * 要求: 
     *      - onlyOwner
     */
    function setRewardValue( uint self , uint one , uint two , uint three ) external;

    /*
     * 领取奖励：奖励不会主动发放，需要用户手动提取
     *
     */
    function receiveReward() external;
}