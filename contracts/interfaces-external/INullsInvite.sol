// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface INullsInvite {

    // 邀请人事件: 被邀请者、邀请者
    event Invite(address beInviter, address superior );
    // 晋升为合伙人事件: 新合伙人
    event NewPartner(address player);
    // 删除合伙人事件: 被删除的合伙人
    event DelPartner(address player);

    /*
     * 设置成为合伙人的条件
     *
     * 要求: 
     *      - onlyOwner
     */
    function setPartnerCondition(
        uint32 buyEggNumber, 
        uint32 inviteNumber
    ) external;

    /*
     * 添加合伙人
     *
     * 要求: 
     *      - onlyOwner
     */
    function addPartner(
        address user
    ) external;

    /*
     * 删除合伙人
     *
     * 要求: 
     *      - onlyOwner
     */
    function delPartner(
        address user
    ) external;

    /*
     * 配置活动合约
     *
     * 要求: 
     *      - onlyOwner
     */
    function setPromotionContract(
        address contractAddr
    ) external;

    // --- public mapping的view方法

    // return: 用户的上级
    function UserSuperior(
        address user
    ) external view returns(address superior);

    // return: 用户买蛋数量
    function BuyEggCount(
        address user
    ) external view returns(uint count);

    // return: 用户有效邀请数(即被邀请人买蛋了)
    function ValidInviteCount(
        address user
    ) external view returns(uint count);

    // return: 用户是否是合伙人
    function Partner(
        address user
    ) external view returns(bool isPartner);
    // ---

    /*
     * 新的邀请，由被邀请者调用此接口
     *
     * 要求: 
     *      - inviter 合法的新用户
     */
    function invite(address inviter) external;

    /*
     * 获取统计信息
     * 返回某一用户的一、二、三级邀请人数量，上级，是否是合伙人
     * 
     */
    function getInviteStatistics(
        address addr
    ) external view returns ( uint32 one , uint32 two , uint32 three , address superior , bool isPartner );

    /*
     * 买蛋后置处理
     *
     * 要求: 
     *      - onlyPromotionContract
     */
    function doAfter(address user, uint count) external;
}