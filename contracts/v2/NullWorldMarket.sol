// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../utils/Ownable.sol";
import "../interfaces/IERC20.sol";

abstract contract NullWorldMarket is Ownable {
    // 宠物挂卖事件: 宠物id、第几次交易、购买token、价格、卖家、时间戳
    event SellPet(
        uint256 petId,
        uint256 count,
        address tokenAddr,
        uint256 price,
        address seller
    );

    modifier checkSupported(address tokenAddr) {
        //todo  可以考虑 不需要白名单erc20

        // 检查tokenAddr合法性
        require(
            SupportedToken[tokenAddr] == true,
            "NullsPetTrade/Unsupported token."
        );
        _;
    }

    // 取消挂卖
    event UnSellPet(uint256 petId, uint256 count, address seller);

    // 成功卖出: 宠物id、第几次交易、卖家、买家
    event SuccessSell(
        uint256 petId,
        uint256 count,
        address seller,
        address buyer
    );

    mapping(address => bool) public SupportedToken;

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

    // 存储出售信息
    mapping(uint256 => SellInfo) public PetSellInfos;

    // 配置用于宠物买卖交易的token（继承ERC20）
    function setSupportedToken(address tokenAddr) external onlyOwner {
        SupportedToken[tokenAddr] = true;
    }

    // 出售
    function sellPet(
        uint256 petId,
        address tokenAddr,
        uint256 price
    ) external checkSupported(tokenAddr) {
        //授权给当前合约
        _SellApproved(petId);
        //获取被出售信息
        SellInfo memory sellInfo = PetSellInfos[petId];

        // 防止重复出售
        require(sellInfo.isSell == false, "NullsPetTrade/Do not resell.");

        sellInfo.isSell = true;
        sellInfo.token = tokenAddr;
        sellInfo.price = price;
        sellInfo.seller = msg.sender;
        PetSellInfos[petId] = sellInfo;
        emit SellPet(petId, sellInfo.count, tokenAddr, price, msg.sender);
    }

    // 取消出售
    function unSellPet(uint256 petId) external {
        // 检查petId所属权
        SellInfo memory sellInfo = PetSellInfos[petId];
        require(
            sellInfo.seller == msg.sender,
            "NullsPetTrade/Pet id is illegal."
        );
        _unSellPet(petId);
    }

    // 购买
    function buyPet(uint256 petId) external {
        // 检查宠物是否在售卖中
        SellInfo memory sellInfo = PetSellInfos[petId];
        require(
            sellInfo.isSell,
            "NullsPetTrade/Currently pets do not support buying."
        );

        // 转token
        require(
            IERC20(sellInfo.token).transferFrom(
                msg.sender,
                sellInfo.seller,
                sellInfo.price
            ),
            "NullsPetTrade/Transfer failed: it may be unapproved."
        );
        // 置位
        sellInfo.isSell = false;
        //出售次数加1
        sellInfo.count += 1;
        //需要
        PetSellInfos[petId] = sellInfo;

        // 转宠物
        _MarketBuy(sellInfo.seller, msg.sender, petId);

        // 发出事件
        emit SuccessSell(petId, sellInfo.count, sellInfo.seller, msg.sender);
    }

    function _unSellPet(uint256 petId) internal {
        // 获取出售信息
        SellInfo memory sellInfo = PetSellInfos[petId];
        if (sellInfo.isSell == true) {
            sellInfo.isSell = false;
            PetSellInfos[petId] = sellInfo;
            emit UnSellPet(petId, sellInfo.count, sellInfo.seller);
        }
    }

    //授权给当前合约
    function _SellApproved(uint256 petId) internal virtual {}

    //转宠物
    function _MarketBuy(
        address from,
        address to,
        uint256 petId
    ) internal virtual {}
}