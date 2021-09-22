// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface INullsEggManager {
    
    // 新宠物事件: 宠物id、批处理下标、itemID、玩家、宠物属性、随机数、uuid(前端开蛋时传递的)
    event NewPet(
        uint petid, 
        uint batchIndex, 
        uint item, 
        address player, 
        bytes32 v, 
        bytes32 rv, 
        string uuid
    );

    // 预开蛋事件: itemID、业务hash、nonce值、过期时间
    event EggNewNonce(
        uint itemId, 
        bytes32 hv, 
        uint256 nonce, 
        uint256 deadline
    );

    /*
     * 设置核心合约
     *
     * 要求: 
     *      - onlyOwner
     */
    function setProxy(address proxy, string memory name) external;

    /*
     * 设置转账交易代理合约
     *
     * 要求: 
     *      - onlyOwner
     */
    function setTransferProxy(address proxy) external;

    /*
     * 配置petToken和EggToken
     *
     * 要求: 
     *      - onlyOwner
     */
    function setPetTokenAndEggToken(address eggToken, address petToken) external;

    /*
     * 配置买蛋后置处理器
     *
     * 要求: 
     *      - onlyOwner
     */
    function setAfterProccess(address afterAddr) external;

    /*
     * 配置支持买蛋的Token
     *
     * 要求: 
     *      - onlyOwner
     */
    function setBuyToken(address token, uint amount) external;

    /*
     * 获取当前合约的场景id
     *
     */
    function getSceneId() external view returns(uint sceneId);

    /*
     * 获取某个token的买蛋单价
     * 
     */
    function getPrice(
        address token
    ) external view returns(uint price);

    /*
     * 买蛋
     * 
     */
    function buy(uint total, address token) external;

    /*
     * 开蛋
     *
     * 要求: 
     *      - total <= 20
     */
    function openMultiple(
        uint total, 
        uint itemId, 
        uint256 deadline, 
        string memory uuid
    ) external;
}