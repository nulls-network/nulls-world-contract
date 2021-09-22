//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface INullWorldMarket {

    struct Token {
        //是否允许
        bool supported;
        //费率
        uint256 feeRate;
    }
    struct SellInfo {
        // 是否在出售
        bool isSell;
        // 购买token
        address token;
        // 价格
        uint256 price;
        // 卖家
        address seller;
        // 交易次数
        uint256 count;
    }

    // 宠物挂卖事件: 宠物id、第几次交易、购买token、价格、卖家
    event SellPet(
        uint256 petId,
        uint256 count,
        address tokenAddr,
        uint256 price,
        address seller
    );

    // 取消挂卖: 宠物id、第几次交易、卖家
    event UnSellPet(
        uint256 petId, 
        uint256 count, 
        address seller
    );

    // 成功卖出: 宠物id、实际成交金额(扣除手续费)、卖家、买家
    event SuccessSell(
        uint256 petId,
        uint256 amount,
        address seller,
        address buyer
    );

     /*
     * 设置转账交易代理合约
     *
     * 要求: 
     *      - onlyOwner
     */
    function setTransferProxy(address proxy) external;

    /*
     * 设置支持买卖宠物的token
     *
     * 要求: 
     *      - onlyOwner
     */
    function setSupportedToken(
        address tokenAddr,
        bool supported,
        uint256 feeRate
    ) external;

    /*
     * 获取token配置信息
     *
     */
    function getSupportedToken(
        address tokenAddr
    ) external view returns(Token memory tokenInfo);
    
    /*
     * 出售宠物
     *
     */
    function sellPet(
        uint256 petId,
        address tokenAddr,
        uint256 price
    ) external;

    /*
     * 获取宠物售卖信息
     *
     */
    function getPetSellInfos(
        uint256 petId
    ) external view returns(SellInfo memory sellInfo);

    /*
     * 取消出售宠物
     *
     */
    function unSellPet(uint256 petId) external;

    /*
     * 购买宠物
     *
     */
    function buyPet(uint256 petId) external;
}