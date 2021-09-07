// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../utils/Ownable.sol";
import "../interfaces/INullsInvite.sol";

// 邀请合约，存储邀请关系
contract NullsInvite is Ownable, INullsInvite {
    
    struct InviteStatistics {
        // 一级邀请人数
        uint countOne;
        // 二级邀请人数
        uint countTwo;
        // 三级邀请人数
        uint countThree;
    }

    // 邀请计数。存储某个用户的邀请计数详情
    mapping(address => InviteStatistics) public UserInviteStatistics;

    // 某个用户的上级地址
    mapping(address => address) public UserSuperior;

    // 某个用户购买恐龙蛋次数
    mapping(address => uint) public BuyEggCount;

    // 调用它的活动合约(onBuyEgg方法)
    address PromotionContract;

    // 邀请事件：被邀请者、区块时间戳、一级邀请人、二级邀请人、三级邀请人
    event Invite(address beInviter, uint timestamp, address one, address two, address three);

    // 晋升为合伙人事件
    event NewPartner(address player, uint timestamp);

    // 成为合伙人的条件，以下条件满足一个即可
    uint MinBuyEggNumber = 3;
    uint MinInviteNumber = 3;

    modifier onlyPromotionContract() {
        require(PromotionContract == _msgSender() , "Ownable: caller is not the promotion contract");
        _;
    }

    // 设置成为合伙人的条件
    function setPartnerCondition(uint buyEggNumber, uint inviteNumber) external onlyOwner {
        MinBuyEggNumber = buyEggNumber;
        MinInviteNumber = inviteNumber;
    }

    // 添加活动合约列表
    function addPromotionContract(address contractAddr) external onlyOwner {
        PromotionContract = contractAddr;
    }

    function getUserType(address user) internal view returns(uint8 userType) {
        InviteStatistics memory userInviterInviteStatistics = UserInviteStatistics[user];

        if(userInviterInviteStatistics.countOne >= MinInviteNumber || BuyEggCount[user] >= MinBuyEggNumber) {
            userType = 1;
        } else {
            userType = 0;
        }
    }

    // 邀请：邀请者、被邀请者
    function invite(address inviter, address beInviter) external onlyOwner {

        // 被邀请用户购买过蛋，证明不是新用户
        require(BuyEggCount[beInviter] == 0, "NullsInvite/The invited user already exists because they have purchased eggs.");

        InviteStatistics memory beInviterInviteStatistics = UserInviteStatistics[beInviter];
        // 被邀请者邀请过其他用户，证明不是新用户
        require(beInviterInviteStatistics.countOne == 0, "NullsInvite/The invited user already exists because it has invited other users.");

        // 被邀请过，证明不是新用户
        require(UserSuperior[beInviter] == address(0), "NullsInvite/The invited user already exists because it has been invited by another user");



        // 更新计数器(一级)
        InviteStatistics memory oneInviterInviteStatistics = UserInviteStatistics[inviter];

        // 如果不是合伙人，判断是否有资格成为新的合伙人
        uint inviterUserType = getUserType(inviter);
        if (inviterUserType == 0) {
            if (oneInviterInviteStatistics.countOne + 1 == MinInviteNumber) {
                // 通过本次邀请成为合伙人了
                emit NewPartner(inviter, block.timestamp);
            }
        }
        oneInviterInviteStatistics.countOne += 1;
        UserInviteStatistics[inviter] = oneInviterInviteStatistics;

        // 更新计数器(二级)
        address twoSuperior = UserSuperior[inviter];
        if(twoSuperior != address(0)) {
            InviteStatistics memory twoInviterInviteStatistics = UserInviteStatistics[twoSuperior];
            twoInviterInviteStatistics.countTwo += 1;
            UserInviteStatistics[twoSuperior] = twoInviterInviteStatistics;

            // 更新计数器(三级)
            address threeSuperior = UserSuperior[twoSuperior];
            if (threeSuperior != address(0)) {
                InviteStatistics memory threeInviterInviteStatistics = UserInviteStatistics[threeSuperior];
                threeInviterInviteStatistics.countThree += 1;
                UserInviteStatistics[threeSuperior] = threeInviterInviteStatistics;

                emit Invite(beInviter, block.timestamp, inviter, twoSuperior, threeSuperior);
                return;
            } else {

                emit Invite(beInviter, block.timestamp, inviter, twoSuperior, address(0));
                return;
            }
        }

        emit Invite(beInviter, block.timestamp, inviter, address(0), address(0));
    }

    // 获取某个邀请统计：用户级别（普通会员0/合伙人1）、一级邀请人数、二级邀请人数、三级邀请人数
    function getInviteStatistics(address user) external view returns(uint8 userType, uint oneCount, uint twoCount, uint threeCount) {

        userType = getUserType(user);
        InviteStatistics memory userInviterInviteStatistics = UserInviteStatistics[user];


        oneCount = userInviterInviteStatistics.countOne;
        twoCount = userInviterInviteStatistics.countTwo;
        threeCount = userInviterInviteStatistics.countThree;
    }



    // 获取一级、二级、三级邀请人及其类型
    function getInvites(address user) external view override returns(address one, uint8 oneType, address two, uint8 twoType, address three, uint threeType) {
        two = address(0);
        three = address(0);
        oneType = 0;
        twoType = 0;
        threeType = 0;

        one = UserSuperior[user];
        if(one != address(0)) {
            oneType = getUserType(one);
            two = UserSuperior[one];

            if(two != address(0)) {
                twoType = getUserType(two);
                three = UserSuperior[two];
                if(three != address(0)) {
                    threeType = getUserType(three);
                }
            }
        }
    }

    // 购买恐龙蛋后的处理逻辑，上层活动合约调用此接口
    // 在这里，只做最底层的计数存储，其他逻辑交给上层活动合约合约去做
    function onBuyEgg(address user, uint count) external override onlyPromotionContract {
        
        uint userType = getUserType(user);
        if (userType == 0) {
            if (BuyEggCount[user] + count > MinBuyEggNumber) {
                emit NewPartner(user, block.timestamp);
            }
        }

        BuyEggCount[user] += count;
    }
}