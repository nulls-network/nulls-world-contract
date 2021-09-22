// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../../utils/Ownable.sol";
import "../../interfaces-external/INullsInvite.sol";
import "../../interfaces/INullsAfterBuyToken.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces-external/INullsPromotion.sol";

// 促销合约
// 所有计算没有使用 SafeMath , 需要考虑溢出情况。
contract NullsPromotion is INullsPromotion, Ownable, INullsAfterBuyToken {

    address RewardToken ;
    uint RewardTotal ;
    uint RewardUsed ;       //已发送奖励

    uint RewardStartTime ;
    uint RewardEndTime ;

    mapping(uint8 => uint ) public override RewardValue; //奖励比例 0:自己 1:一级  2:二级 3:三级

    // 记录某个用户的奖励金额
    mapping(address => uint) public override UserRewards;

    // 存储邀请信息的底层合约
    INullsInvite InviteContract;

    // eggManager合约
    address EggContractAddr;

    modifier onlyEggContract() {
        require(EggContractAddr == _msgSender() , "Ownable: caller is not the egg contract");
        _;
    }

    modifier updateStatistics( address user , uint total ) {
        //邀请关系计数  
        InviteContract.doAfter(user, total );
        _ ;
    }

    function setReward( address token , uint total , uint startTime , uint endTime ) external override onlyOwner {
        RewardToken = token ;
        RewardTotal = total ;
        RewardStartTime = startTime ;
        RewardEndTime = endTime ;
    }

    function setBaseInfo( address inviteAddr , address eggAddr ) external override onlyOwner {
        InviteContract = INullsInvite( inviteAddr ) ;
        EggContractAddr = eggAddr ; 
    }

    function setRewardValue( uint self , uint one , uint two , uint three ) external override onlyOwner {
        RewardValue[0] = self ;
        RewardValue[1] = one ;
        RewardValue[2] = two ;
        RewardValue[3] = three ; 
    }

    function doReward(address buyer, address current , uint total , uint8 index ) internal {
        if( current == address(0) || index >=4 ){
            return ;
        }
        uint balance = RewardTotal - RewardUsed;
        if(balance > 0) {
            (,,,address superior,bool isPartner) = InviteContract.getInviteStatistics( current );
            // 买蛋者、直接上级一定可以获取到奖励
            if (index == 0 || index == 1 || isPartner) {
                uint rewardValue = RewardValue[index] * total ;
                if( rewardValue > balance ) {
                    rewardValue = balance ;
                }
                // IERC20(RewardToken).transfer( current , rewardValue );
                UserRewards[current] += rewardValue;
                RewardUsed += rewardValue ; 
                emit RewardRecord(buyer, current, rewardValue, index);
            }
            
            index++ ;
            doReward(buyer, superior, total, index);
        }
    }

    function receiveReward() external override {
        uint total = UserRewards[msg.sender];
        uint balance = IERC20(RewardToken).balanceOf( address(this) ) ;
        if (total > 0 && balance > 0) {
            if (total > balance) {
                total = balance;
            }
            IERC20(RewardToken).transfer( msg.sender , total);
            UserRewards[msg.sender] = 0;
            emit ReceiveReward(msg.sender, total);
        }
    }

    function doAfter(address buyer, uint total , address , uint ) external override 
        updateStatistics( buyer , total ) onlyEggContract {

        if( block.timestamp < RewardStartTime ||  block.timestamp > RewardEndTime ) {
            return ;
        }

        doReward(buyer,  buyer , total, 0 );
    }
}