// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../utils/Ownable.sol";
import "../interfaces/INullsInvite.sol";
import "../interfaces/INullsAfterBuyToken.sol";
import "../interfaces/IERC20.sol";

// 促销合约
// 所有计算没有使用 SafeMath , 需要考虑溢出情况。
contract NullsPromotion is Ownable, INullsAfterBuyToken {

    address RewardToken ;
    uint RewardTotal ;
    uint RewardUsed ;       //已发送奖励

    uint RewardStartTime ;
    uint RewardEndTime ;

    mapping(uint8 => uint ) RewardValue ; //奖励比例 0:自己 1:一级  2:二级 3:三级

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

    event RewardRecord( address buyer , uint total , address payToken , uint payTotal ) ;

    function setReward( address token , uint total , uint startTime , uint endTime ) external onlyOwner {
        RewardToken = token ;
        RewardTotal = total ;
        RewardStartTime = startTime ;
        RewardEndTime = endTime ;
    }

    function setBaseInfo( address inviteAddr , address eggAddr ) external onlyOwner {
        InviteContract = INullsInvite( inviteAddr ) ;
        EggContractAddr = eggAddr ; 
    }

    function setRewardValue( uint self , uint one , uint two , uint three ) external onlyOwner {
        RewardValue[0] = self ;
        RewardValue[1] = one ;
        RewardValue[2] = two ;
        RewardValue[3] = three ; 
    }

    function doReward( address current , uint total , uint8 index ) internal {
        if( current == address(0) || index >=4 ){
            return ;
        }
        uint balance = IERC20(RewardToken).balanceOf( address(this) ) ;
        if( balance > 0 && RewardTotal > RewardUsed ) {
            uint rewardValue = RewardValue[index] * total ;
            if( rewardValue > balance ) {
                rewardValue = balance ;
            }
            IERC20(RewardToken).transfer( current , rewardValue );
            RewardUsed += rewardValue ; 
            index++ ;

            (,,,address superior,bool isPartner) = InviteContract.getInviteStatistics( current );
            if( isPartner == false ) {
                superior = address(0) ; // return
            }
            doReward(superior, total, index);
        }
    }   

    function doAfter(address buyer, uint total , address payToken , uint payAmount ) external override 
        updateStatistics( buyer , total ) onlyEggContract {

        if( block.timestamp < RewardStartTime ||  block.timestamp > RewardEndTime ) {
            return ;
        }

        doReward( buyer , total, 0 );

        emit RewardRecord(buyer, total, payToken, payAmount );
    }
}