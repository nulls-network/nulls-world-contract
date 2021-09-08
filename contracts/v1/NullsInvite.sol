// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../utils/Ownable.sol";
import "../interfaces/INullsInvite.sol";

// 邀请合约，存储邀请关系
contract NullsInvite is Ownable, INullsInvite {
    
    // struct InviteStatistics {
    //     // 一级邀请人数
    //     uint countOne;
    //     // 二级邀请人数
    //     uint countTwo;
    //     // 三级邀请人数
    //     uint countThree;
    // }
 
    // 邀请计数。存储某个用户的邀请计数详情
    mapping(address => mapping(uint32 => uint32)) public UserinviteStatistics;

    // 某个用户的上级地址
    mapping(address => address) public UserSuperior;

    // 某个用户购买恐龙蛋次数
    mapping(address => uint) public BuyEggCount;
    // 某个用户的下级购买恐龙蛋的数量
    mapping(address => uint) public ValidInviteCount;

    mapping(address => bool ) public Partner ;

    // 调用它的活动合约.doAfter()
    address PromotionContract;

    event Invite(address beInviter, uint timestamp, address superior );

    // 晋升为合伙人事件
    event NewPartner(address player, uint timestamp);

    // 成为合伙人的条件，以下条件满足一个即可
    // 自己买蛋的总数
    uint32 MinBuyEggNumber = 3;
    // 下级买蛋的总数
    uint32 MinInviteNumber = 3;

    modifier onlyPromotionContract() {
        require(PromotionContract == _msgSender() , "Ownable: caller is not the promotion contract");
        _;
    }

    // 设置成为合伙人的条件
    function setPartnerCondition(uint32 buyEggNumber, uint32 inviteNumber) external onlyOwner {
        MinBuyEggNumber = buyEggNumber;
        MinInviteNumber = inviteNumber;
    }

    // 添加活动合约列表
    function addPromotionContract(address contractAddr) external onlyOwner {
        PromotionContract = contractAddr;
    }

    function updateInviteStatistics( address current , uint32 index ) internal returns ( address superior ) {
        if( superior == address(0) ) {
            return address(0) ;
        }
        
        if( index > 2 ) {
            return address(0) ;
        }

        UserinviteStatistics[current][index] = UserinviteStatistics[current][index] + 1  ; 
        superior = UserSuperior[current] ;
        return updateInviteStatistics( superior , index ++ ) ;
    }

    function getInviteStatistics( address addr ) public view override returns ( uint32 one , uint32 two , uint32 three , address superior , bool isPartner ) {
        one = UserinviteStatistics[addr][0] ;
        two = UserinviteStatistics[addr][1] ;
        three = UserinviteStatistics[addr][2] ;
        superior = UserSuperior[addr] ; 
        isPartner = Partner[addr];
    }

    function invite(address inviter ) external {
        address beInviter = msg.sender ;
        // 被邀请用户购买过蛋，证明不是新用户
        require(BuyEggCount[beInviter] == 0, "NullsInvite/The invited user already exists because they have purchased eggs.");
        // 被邀请过，证明不是新用户
        require(UserSuperior[beInviter] == address(0), "NullsInvite/The invited user already exists because it has been invited by another user");

        updateInviteStatistics( inviter , 0 );
        emit Invite(beInviter, block.timestamp , inviter );
    }

    // 购买恐龙蛋后的处理逻辑，上层活动合约调用此接口
    // 在这里，只做最底层的计数存储，其他逻辑交给上层活动合约合约去做
    function doAfter(address user, uint count) external override onlyPromotionContract {
        
        if (count == 0) {
            return;
        }

        // 判断当前用户是否是首次买蛋
        if (BuyEggCount[user] == 0) {
            address superior = UserSuperior[user];
            if (superior != address(0)) {
                
                ValidInviteCount[superior] += 1;
                ( , , , , bool superiorIsPartner )  = getInviteStatistics(superior);
                if (superiorIsPartner == false) {
                    if ( ValidInviteCount[superior] >= MinInviteNumber ) {
                        Partner[superior] = true;
                        emit NewPartner( superior , block.timestamp ) ;
                    }
                }
            }
        }
        
        bool isPartner = Partner[user];
        BuyEggCount[user] += count;

        if( isPartner == false ) {
            if( BuyEggCount[user] >= MinBuyEggNumber ) {
                Partner[user] = true ;
                emit NewPartner( user , block.timestamp ) ;
            }
        }

    }
}