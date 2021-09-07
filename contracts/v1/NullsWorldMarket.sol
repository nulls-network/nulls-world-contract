// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../utils/Ownable.sol";
import "../interfaces/INullsPetToken.sol";
import "../interfaces/IERC20.sol";

contract NullsWorldMarket is Ownable{

    // 宠物挂卖事件: 宠物id、第几次交易、购买token、价格、卖家、时间戳
    event SellPet(uint256 petId, uint count, address tokenAddr ,uint price, address seller, uint timestamp);

    // 取消挂卖
    event UnSellPet(uint256 petId, uint count, address seller);

    // 成功卖出: 宠物id、第几次交易、卖家、买家、时间戳(根据时间戳可计算耗时多久卖出)
    event SuccessSell(uint256 petId, uint count, address seller, address buyer, uint timestamp);

    address PetToken = address(0);

    // 存储支持交易的token
    mapping( address => bool ) public SupportedToken;

    struct SellInfo {
        // 是否在出售
        bool isSell;
        // 购买token
        address token;
        // 价格
        uint price;
        // 卖家
        address seller;
        // 交易次数
        uint count;
    }

    // 存储出售信息
    mapping(uint256 => SellInfo) public PetSellInfos;
 
    function setPetToken( address petToken ) external onlyOwner {
        PetToken = petToken ;
    }

    // 配置用于宠物买卖交易的token（继承ERC20）
    function setSupportedToken(address tokenAddr) external onlyOwner {
        SupportedToken[tokenAddr] = true;
    }

    // 出售
    function sellPet(uint256 petId, address tokenAddr, uint price) external {
        // 检查petId所属权
        require(INullsPetToken( PetToken ).ownerOf(petId) == msg.sender, "NullsPetTrade/Pet id is illegal.");

        // 检查tokenAddr合法性
        require(SupportedToken[tokenAddr] == true, "NullsPetTrade/Unsupported token.");

        // 判断是否已授权
        require(INullsPetToken(PetToken).getApproved(petId) == address(this), "NullsPetTrade/Current pet is not approved.");

        // 先获取一次
        SellInfo memory sellInfo = PetSellInfos[petId];

        // 防止重复出售
        require(sellInfo.isSell == false, "NullsPetTrade/Do not resell.");

        sellInfo.isSell = true;
        sellInfo.token = tokenAddr;
        sellInfo.price = price;
        sellInfo.seller = msg.sender;
        // 从未售卖过= 0+1
        sellInfo.count += 1;

        emit SellPet(petId, sellInfo.count, tokenAddr , price, msg.sender, block.timestamp);
    }

    // 取消出售
    function unSellPet(uint256 petId) external {
        // 检查petId所属权
        require(INullsPetToken( PetToken ).ownerOf(petId) == msg.sender, "NullsPetTrade/Pet id is illegal.");

        // 获取出售信息
        SellInfo memory sellInfo = PetSellInfos[petId];

        if (sellInfo.isSell == true) {

            sellInfo.isSell = false;
            // count值再减回去
            sellInfo.count -= 1;
            PetSellInfos[petId] = sellInfo;

            // 这里的count应该和卖时的count对应
            emit UnSellPet(petId, sellInfo.count + 1, msg.sender);
        }
    }

    // 购买
    function buyPet(uint256 petId) external {
        // 检查宠物是否在售卖中
        SellInfo memory sellInfo = PetSellInfos[petId];
        require(sellInfo.isSell, "NullsPetTrade/Currently pets do not support buying.");

        // 检查卖家宠物是否可以转让
        require(INullsPetToken(PetToken).getApproved(petId) == address(this), "NullsPetTrade/Current pet is not approved.");

        // 转token
        require(IERC20(sellInfo.token).transferFrom(msg.sender, sellInfo.seller, sellInfo.price), "NullsPetTrade/Transfer failed: it may be unapproved.");

        // 转宠物
        INullsPetToken(PetToken).transferFrom(sellInfo.seller, msg.sender, petId);

        // 置位
        sellInfo.isSell = false;

        // 发出事件
        emit SuccessSell(petId, sellInfo.count, sellInfo.seller, msg.sender, block.timestamp);
    }
}