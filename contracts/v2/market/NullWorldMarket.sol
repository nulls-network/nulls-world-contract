// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../../interfaces/ITransferProxy.sol";
import "../../interfaces-external/INullWorldMarket.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract NullWorldMarket is INullWorldMarket, Ownable {
    ITransferProxy TransferProxy;

    //允许出售的erc20币种
    mapping(address => Token) SupportedToken;
    // 存储出售信息
    mapping(uint256 => SellInfo) PetSellInfos;

    function setTransferProxy(address proxy) external override onlyOwner {
        TransferProxy = ITransferProxy(proxy);
    }

    // 配置用于宠物买卖交易的token（继承ERC20）
    function setSupportedToken(
        address tokenAddr,
        bool supported,
        uint256 feeRate
    ) external override onlyOwner {
        Token memory token = SupportedToken[tokenAddr];
        token.supported = supported;
        token.feeRate = feeRate;
        SupportedToken[tokenAddr] = token;
    }

    function getSupportedToken(
        address tokenAddr
    ) external override view returns(Token memory tokenInfo) {
        tokenInfo = SupportedToken[tokenAddr];
    }

    function getPetSellInfos(
        uint256 petId
    ) external override view returns(SellInfo memory sellInfo) {
        sellInfo = PetSellInfos[petId];
    }

    // 出售
    function sellPet(
        uint256 petId,
        address tokenAddr,
        uint256 price
    ) external override {
        // 检查tokenAddr合法性
        require(
            SupportedToken[tokenAddr].supported == true,
            "NullsPetTrade/Unsupported token."
        );
        //校验是否能Sell
        _checkSell(petId);
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
    function unSellPet(uint256 petId) external override {
        // 检查petId所属权
        SellInfo memory sellInfo = PetSellInfos[petId];
        require(
            sellInfo.seller == msg.sender,
            "NullsPetTrade/Pet id is illegal."
        );
        _unSellPet(petId);
    }

    // 购买
    function buyPet(uint256 petId) external override {
        // 检查宠物是否在售卖中
        SellInfo memory sellInfo = PetSellInfos[petId];
        require(
            sellInfo.isSell,
            "NullsPetTrade/Currently pets do not support buying."
        );
        uint256 amount = sellInfo.price;
        Token memory token = SupportedToken[sellInfo.token];
        uint256 fee = (amount * token.feeRate) / 10000;
        amount -= fee;
        //转手续费
        if (fee > 0) {
            TransferProxy.erc20TransferFrom(sellInfo.token, msg.sender, owner(), fee);
        }

        // 转token
        TransferProxy.erc20TransferFrom(sellInfo.token, msg.sender, sellInfo.seller, amount);
        // 置位
        sellInfo.isSell = false;
        //出售次数加1
        sellInfo.count += 1;
        //需要
        PetSellInfos[petId] = sellInfo;

        // 转宠物
        _buyPet(sellInfo.seller, msg.sender, petId);

        // 发出事件
        emit SuccessSell(petId, amount, sellInfo.seller, msg.sender);
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

    //校验是否能出售
    function _checkSell(uint256 petId) internal virtual {}

    //转宠物
    function _buyPet(
        address from,
        address to,
        uint256 petId
    ) internal virtual {}
}
