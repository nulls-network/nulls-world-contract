// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../../interfaces-external/INullsInvite.sol";
import "../../interfaces/INullsAfterBuyEgg.sol";
import "../../interfaces/INullsAfterPk.sol";
import "../../interfaces/INullsWorldToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// 正式上线后的活动合约
// 买蛋、PK获取积分，积分兑换NwtToken
contract NullsExcitation is Ownable, INullsAfterBuyEgg, INullsAfterPk {

    // 存储邀请信息的底层合约
    INullsInvite InviteContract;

    INullsWorldToken NwtToken;

    mapping(address => bool) WhiteList;

    //奖励比例 0:自己 1:一级  2:二级 3:三级
    mapping(uint8 => uint ) public RewardValue;

    modifier onlyWhiteList() {
        require(WhiteList[_msgSender()], "Ownable: caller is not the white list contract");
        _;
    }

    modifier updateStatistics( address user , uint total ) {
        //邀请关系计数  
        InviteContract.doAfter(user, total );
        _ ;
    }

    function setBaseInfo(address inviteAddr, address nwtToken) external onlyOwner {
        InviteContract = INullsInvite(inviteAddr);
        NwtToken = INullsWorldToken(nwtToken);
    }

    function setRewardValue( uint self , uint one , uint two , uint three ) external onlyOwner {
        RewardValue[0] = self ;
        RewardValue[1] = one ;
        RewardValue[2] = two ;
        RewardValue[3] = three ; 
    }

    function _doReward(address buyer, address current, uint amount, uint8 index) internal {
        if( current == address(0) || index >=4 ){
            return ;
        }
        (,,,address superior,bool isPartner) = InviteContract.getInviteStatistics( current );
        if (index == 0 || index == 1 || isPartner) {
            uint score = amount * RewardValue[index];
            NwtToken.incrDayScore(current,score);
        }
        index++;
        _doReward(buyer, superior, amount, index);
    }

    function doAfterIdo(address user, uint score) external onlyWhiteList {
        NwtToken.incrDayScore(user, score);
    }

    // When buying eggs
    function doAfter(address buyer, uint total , address , uint amount) external override 
        updateStatistics( buyer , total ) onlyWhiteList {
        _doReward(buyer, buyer, amount, 0);
    }

    // When participating in pk
    function doAfterPk(address user, address, uint payAmount ) external override onlyWhiteList {
        _doReward(user, user, payAmount, 0);
    }
}