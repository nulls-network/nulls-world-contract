// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../utils/Ownable.sol";
import "../interfaces/INullsInvite.sol";
import "../interfaces/INullsAfterBuyToken.sol";
import "../interfaces/INullsWorldToken.sol";

// 促销合约
contract NullsPromotion is Ownable, INullsAfterBuyToken {

    struct RewardTokenConfig {
        // 奖励token地址
        address tokenAddr;
        // 总奖励金额
        uint totalReward;
        // 奖池余额
        uint rewardPoolBalance;
    }

    // 买蛋者自身、1级邀请人、2级邀请人、3级邀请人奖励
    struct RewardLevelConfig {
        uint self;
        uint one;
        uint two;
        uint three;
    }

    struct TimeConfig {
        uint start;
        uint end;
    }

    RewardTokenConfig RewardNullsToken; 

    RewardLevelConfig RewardLevel;

    TimeConfig TConfig;

    // 存储邀请信息的底层合约
    INullsInvite InviteContract;

    // eggManager合约
    address EggContractAddr;

    // 奖励发送事件: 发给谁、谁触发的、金额、时间戳
    event PayReward(address target, address caller, uint total, uint timestamp);

    modifier onlyEggContract() {
        require(EggContractAddr == _msgSender() , "Ownable: caller is not the egg contract");
        _;
    }

    constructor(address inviteContractAddr, address eggContractAddr) {
        InviteContract = INullsInvite(inviteContractAddr);
        EggContractAddr = eggContractAddr;
    }

    // 调用此方法前需要先授权，以保证本合约可以增发RewardToken
    function setRewardToken(address addr, uint total) external onlyOwner {
        RewardNullsToken.tokenAddr = addr;
        RewardNullsToken.totalReward = total;
        RewardNullsToken.rewardPoolBalance = total;
    }

    // 设置各邀请级别的奖励金额
    function setRewardCount(uint self, uint one, uint two, uint three) external onlyOwner {
        RewardLevel.self = self;
        RewardLevel.one = one;
        RewardLevel.two = two;
        RewardLevel.three = three;
    }

    // 设置活动时间区间
    function setPromotionTime(uint startTime, uint endTime) external onlyOwner {
        TConfig.start = startTime;
        TConfig.end = endTime;
    }

    // 获取能发的最大奖励
    function getMaxReward(uint rewardValue) internal view returns(uint maxReward) {
        uint balance = RewardNullsToken.rewardPoolBalance;
        if (balance > rewardValue) {
            maxReward = rewardValue;
        } else {
            maxReward = balance;
        }
    }

    // 给谁发、谁触发的（谁买蛋）、发送金额
    function payoutReward(address target, address caller, uint total) internal {
        
        total = getMaxReward(total);
        if (total == 0) {
            return;
        }
        // 调用c20发送奖励
        INullsWorldToken(RewardNullsToken.tokenAddr).mint(target, total);

        // 更新RewardBalance
        RewardNullsToken.rewardPoolBalance -= total;

        emit PayReward(target, caller, total, block.timestamp);
    }

    function doAfter(address user, uint total , address  , uint  ) external override onlyEggContract {

        // 调用底层邀请合约，存储
        InviteContract.onBuyEgg(user, total);

        // 不在活动时间不处理
        if(block.timestamp < TConfig.start || block.timestamp > TConfig.end) {
            return;
        }

        // 奖池为0不处理
        if(RewardNullsToken.rewardPoolBalance == 0) {
            return;
        }

        payoutReward(user, user, total * RewardLevel.self);

        // 获取一级、二级、三级邀请人
        (address one, uint8 oneType, address two, uint8 twoType, address three, uint threeType) = InviteContract.getInvites(user);

        // 给一级邀请人发奖励，只有合伙人才能获得奖励
        if(one != address(0) && oneType == 1) {
            payoutReward(one, user, total * RewardLevel.one);
        }

        // 给二级邀请人发奖励
        if(two != address(0) && twoType == 1) {
            payoutReward(two, user, total * RewardLevel.two);
        }

        // 给三级邀请人发奖励
        if(three != address(0) && threeType == 1) {
            payoutReward(three, user, total * RewardLevel.three);
        }

    }
}