// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/INullsBigPrizePool.sol";

// 大奖池合约
contract NullsBigPrizePool is INullsBigPrizePool, Ownable {
    address public override TokenAddr;

    // 开始计算天数的时间戳(s)
    uint256 public override BeginTime;

    // 当前天数
    uint256 public override DayIndex;

    // 奖池当前Token总数量
    uint256 public override PoolTokenAmount;

    // 总转出百分比的100倍
    uint8 public override TotalPercent;

    // DayIndex 和 当天的总Token数量映射关系
    mapping(uint256 => uint256) public override DayTokenAmount;

    // 某个用户当前的固定转账额度
    mapping(address => uint8) public override UserCurrentTransferPercent;

    // 记录某个用户某天的固定转账额度
    // 解决中途修改额度的问题，只在修改额度时写入
    mapping(address => mapping(uint256 => uint8)) public UserDayTransferPercent;
    // 修改历史
    mapping(address => uint256[]) public UserTransferPercentModifyHistory;

    // Day => 总百分比之间的映射关系
    // 只在修改额度时记录
    mapping(uint256 => uint8) public DayTotalPercent;
    // 总额度的修改历史记录
    uint256[] public TotalPercentModifyHistory;

    mapping(address => mapping(uint256 => bool)) public TransferOutRecord;

    mapping(address => uint) public override RewardStartDayIndex;

    uint256 public Balance;
    constructor(uint256 ts) {
        if (ts == 0) {
            ts = block.timestamp;
        }
        BeginTime = ts;
    }

    function setTokenAddr(address addr) external override onlyOwner {
        TokenAddr = addr;
    }

    function setTransferPercent(address addr, uint8 percent)
        external
        override
        onlyOwner
    {
        uint256 currentDayIndex = _getDayIndex();

        uint dayIndex = RewardStartDayIndex[addr];

        // 获取旧额度
        uint8 oldPercent = UserCurrentTransferPercent[addr];

        if (dayIndex == 0) {
            RewardStartDayIndex[addr] = currentDayIndex + 1;
        }

        // 更新当前总额度
        TotalPercent = TotalPercent - oldPercent + percent;
        require(
            TotalPercent <= 100,
            "NullsBigPrizePool/The total percentage cannot be greater than 100"
        );

        // 更新用户当前的固定额度
        UserCurrentTransferPercent[addr] = percent;

        uint256[] storage history = UserTransferPercentModifyHistory[addr];

        // 插入用户percent修改记录
        // 修改记录为空，或最后一次修改记录不是当天，则插入修改记录
        if (
            history.length == 0 ||
            history[history.length - 1] != currentDayIndex
        ) {
            history.push(currentDayIndex);
        }
        UserDayTransferPercent[addr][currentDayIndex] = percent;

        // 插入总percent修改记录
        if (
            TotalPercentModifyHistory.length == 0 ||
            TotalPercentModifyHistory[TotalPercentModifyHistory.length - 1] !=
            currentDayIndex
        ) {
            TotalPercentModifyHistory.push(currentDayIndex);
        }
        DayTotalPercent[currentDayIndex] = TotalPercent;
    }

    function _getDayIndex() internal view returns (uint256 idx) {
        idx = (block.timestamp - BeginTime) / (1 days);
    }

    function _getIndexInTrack(uint256[] memory track, uint256 currentIndex)
        internal
        pure
        returns (bool isSuccess, uint256 index)
    {
        isSuccess = false;
        index = 0;
        for (uint256 i = 0; i < track.length; i++) {
            if (
                track[i] <= currentIndex &&
                (i == track.length - 1 || track[i + 1] > currentIndex)
            ) {
                isSuccess = true;
                index = track[i];
            }
        }
    }

    function _getUserDayTransferPercent(address user, uint256 dayIndex)
        internal
        view
        returns (uint8 percent)
    {
        (bool isSuccess, uint256 index) = _getIndexInTrack(
            UserTransferPercentModifyHistory[user],
            dayIndex
        );
        if (isSuccess) {
            percent = UserDayTransferPercent[msg.sender][index];
        } else {
            percent = 0;
        }
    }

    function getUserDayTransferPercent(address user, uint256 dayIndex)
        external
        view
        override
        returns (uint8 percent)
    {
        percent = _getUserDayTransferPercent(user, dayIndex);
    }

    function _getDayTotalPercent(
        uint256[] memory totalPercentModifyHistory,
        uint256 dayIndex
    ) internal view returns (uint8 percent) {
        (bool isSuccess, uint256 index) = _getIndexInTrack(
            totalPercentModifyHistory,
            dayIndex
        );
        if (isSuccess) {
            percent = DayTotalPercent[index];
        } else {
            percent = 0;
        }
    }

    function getDayTotalPercent(uint256 dayIndex)
        external
        view
        override
        returns (uint8 percent)
    {
        percent = _getDayTotalPercent(TotalPercentModifyHistory, dayIndex);
    }

    function _updateStatistics(uint256 amount) internal {
        uint256 currentDayIndex = _getDayIndex();
        uint256 tmpPoolTokenAmount = PoolTokenAmount;
        bool tmpPoolTokenAmountIsModify = false;

        // 延后更新DayTokenAmount
        // 因为每天都要减去授权的部分，故当天的DayTokenAmount至少到第二天才能计算出来
        if (DayIndex != currentDayIndex) {
            uint256[] memory history = TotalPercentModifyHistory;
            for (uint256 i = DayIndex; i < currentDayIndex; i++) {
                uint8 percent = _getDayTotalPercent(history, i);
                if (percent > 0) {
                    tmpPoolTokenAmount -= (tmpPoolTokenAmount * percent) / 100;
                    tmpPoolTokenAmountIsModify = true;
                }
                // else: 当前day没有对应的授权数据，奖池大小不变
                DayTokenAmount[i] = tmpPoolTokenAmount;
            }
            DayIndex = currentDayIndex;
        }

        if (amount != 0) {
            tmpPoolTokenAmount += amount;
            tmpPoolTokenAmountIsModify = true;
        }

        if (tmpPoolTokenAmountIsModify) {
            PoolTokenAmount = tmpPoolTokenAmount;
        }
    }

    // 向大奖池汇款
    function transferIn() external override {
        uint256 newBalance = IERC20(TokenAddr).balanceOf(address(this));
        _updateStatistics(newBalance - Balance);
        Balance = newBalance;
    }

    function updateStatistics() external {
        _updateStatistics(0);
    }

    // 从大奖池转出,按照预先设定的百分比转出
    // actualAmount: 实际领取的数量
    function transferOut(uint256 dayIndex)
        external
        override
        returns (uint256 actualAmount)
    {
        require(dayIndex < _getDayIndex(), "NullsBigPrizePool/Must be receive by next day.");
        
        require(TransferOutRecord[msg.sender][dayIndex] == false, "NullsBigPrizePool/Do not receive repeatedly.");

        uint8 percent = _getUserDayTransferPercent(msg.sender, dayIndex);
        if (percent == 0) {
            return 0;
        }

        uint256 dayTokenAmount = DayTokenAmount[dayIndex];
        if (dayTokenAmount == 0) {
            _updateStatistics(0);
            dayTokenAmount = DayTokenAmount[dayIndex];
            if (dayTokenAmount == 0) {
                return 0;
            }
        }
        uint256 amount = (dayTokenAmount * percent) / 100;
        IERC20(TokenAddr).transfer(msg.sender, amount);
        Balance -= amount;
        TransferOutRecord[msg.sender][dayIndex] = true;
        emit RewardReceived(msg.sender, amount, dayIndex, TokenAddr);
        return amount;
    }
}
