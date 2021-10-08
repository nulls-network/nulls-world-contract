//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakingCore is Ownable, ReentrancyGuard {
    using Math for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private Id;
    //stakingAccount
    struct Account {
        address account;
        uint256 amount;
        uint256 total;
        uint256 start;
        uint256 end;
    }

    struct Rewards {
        uint256 amount;
        uint256 totalStaking;
        uint256 timestamp;
    }

    address public PrizePool;
    address public StakingToken;

    uint256 public StartTime;

    uint256 public TotalSupply;

    mapping(address => uint256) public BalanceOf;

    mapping(address => Account) public Voucher;

    mapping(uint256 => Account) DayVoucher;

    mapping(uint16 => uint256) Coefficient;

    Rewards[] DayRewards;

    event Stake(address indexed sender,uint256 amount);
    event StakeDay(address indexed sender,uint256 amount,uint256 id);

    constructor(
        uint256 _startTime,
        address _stakingToken,
        address _prizePool
    ) {
        StartTime = _startTime;
        StakingToken = _stakingToken;
        PrizePool = _prizePool;
    }

    modifier onStart() {
        require(block.timestamp > StartTime, "");
        _;
    }

    function _useId() internal returns (uint256 id) {
        id = Id.current();
        Id.increment();
    }

    function getCoefficient(uint16 time) public view returns (uint256) {
        return Coefficient[time];
    }

    function test() public view  returns (uint256){
        return DayRewards.length;
    }

    function stakeDay(uint256 amount, uint16 day)  external nonReentrant{
        require(IERC20(StakingToken).transferFrom(msg.sender, address(this), amount), "transfer error");
        uint256 coefficient = getCoefficient(day);
        require(coefficient > 0, "");
        uint256 start = DayRewards.length + 1;
        coefficient = (amount * coefficient) / 1000;
        Account memory account = Account({
            account: msg.sender,
            amount: amount,
            total: coefficient,
            start: start,
            end: start + day
        });
        uint256 id = _useId();
        DayVoucher[id] = account;
        TotalSupply += coefficient;
        BalanceOf[msg.sender] += coefficient;
        emit StakeDay(msg.sender, amount, id);
    }

    function stake(uint256 amount) external nonReentrant {
        require(IERC20(StakingToken).transferFrom(msg.sender, address(this), amount), "transfer error");
        // n+1
        uint256 start = DayRewards.length + 1;
        Account memory account = Voucher[msg.sender];
        account.amount += amount;
        account.total += amount;
        if (account.amount == 0) {
            account.account = msg.sender;
            account.start = start;
        }
        Voucher[msg.sender] = account;
        TotalSupply += amount;
        BalanceOf[msg.sender] += amount;
        emit Stake(msg.sender, amount);
    }

    function notifyRewards() external onlyOwner {
        uint256 len = DayRewards.length;
        uint256 time = len > 0 ? DayRewards[len - 1].timestamp : StartTime;
        uint256 day = (block.timestamp - time) / 1 days;
        if (day > 0) {
            //todo prizePoolAddress
            uint256 amount = 111;
            for (uint256 index = 0; index < day; index++) {
                Rewards memory rewards = Rewards({
                    amount: amount,
                    totalStaking: TotalSupply,
                    timestamp: time + 1 days
                });
                DayRewards.push(rewards);
            }
        }
    }

    function getDayRewards(uint256 key) external {
        Account memory account = DayVoucher[key];
        uint256 start = _reward(account);
        account.start = start;
        if (start == account.end) {
            TotalSupply -= account.total;
            BalanceOf[msg.sender] -= account.total;
        }
        DayVoucher[key] = account;
    }

    function getReward() external nonReentrant {
        Account memory account = Voucher[msg.sender];
        uint256 start = _reward(account);
        account.start = start;

        Voucher[msg.sender] = account;
    }

    function withdraw(uint256 amount) external nonReentrant {
        Account memory account = Voucher[msg.sender];
        account.start = _reward(account);
        if (account.start == DayRewards.length) {
            IERC20(StakingToken).transfer(msg.sender, account.amount);
            account.amount -= amount;
        }
        TotalSupply -= amount;
        BalanceOf[msg.sender] -= amount;
        Voucher[msg.sender] = account;
    }

    function _reward(Account memory account) internal returns (uint256) {
        require(account.account == msg.sender, "");
        uint256 len = account.end == 0
            ? DayRewards.length
            : Math.min(DayRewards.length, account.end);
        len = Math.min(len, account.start + 20);
        uint256 start = account.start;
        uint256 amount = 0;
        for (; start < len; start++) {
            Rewards memory rewards = DayRewards[start];
            unchecked {
                amount +=
                    (account.total * rewards.amount) /
                    rewards.totalStaking;
            }
        }
        // todo erc20 address
        require(
            IERC20(address(0)).transfer(msg.sender, amount),
            "transfer error"
        );
        return start;
    }

}
