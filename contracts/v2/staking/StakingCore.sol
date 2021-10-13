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
    Counters.Counter private IdCounter;
    //stakingAccount
    struct Account {
        address account;
        uint256 amount;
        uint256 total;
        uint256 start;
        uint256 unlockTime;
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

    uint256 public TotalRewards;

    mapping(address => uint256) public BalanceOf;

    mapping(address => Account) public Voucher;

    mapping(uint256 => Account) DayVoucher;

    mapping(uint256 => uint256) Coefficient;

    Rewards[] DayRewards;

    event Stake(address indexed account, uint256 amount);
    event StakeDay(address indexed account, uint256 amount,uint256 key);
    event Withdraw(address indexed account, uint256 amount);
    event WithdrawDay(address indexed account, uint256 amount, uint256 key);
    event SetCoefficient(uint256 indexed time, uint256 coefficient);
    event NotifyRewards(uint256 indexed index, uint256 rewards,uint256 totalStaking,uint256 day);
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

    function _useKey() internal returns (uint256 key) {
        IdCounter.increment();
        key = IdCounter.current();
    }

    function getCoefficient(uint256 time) public view returns (uint256 ) {
        return Coefficient[time];
    }

    function setCoefficient(uint256 time,uint256 coefficient) external  {
         Coefficient[time] = coefficient;
         emit SetCoefficient(time,coefficient);
    }



    function stakeDay(uint256 amount, uint16 time)  external nonReentrant onStart{
        require(IERC20(StakingToken).transferFrom(msg.sender, address(this), amount), "transfer error");
        uint256 coefficient = getCoefficient(time);
        require(coefficient > 0, "Coefficient not exist");
        uint256 start = DayRewards.length + 1;
        coefficient = (amount * coefficient) / 1000;
        Account memory account = Account({
            account: msg.sender,
            amount: amount,
            total: coefficient,
            start: start,
            unlockTime: block.timestamp + time
        });
        uint256 key = _useKey();
        DayVoucher[key] = account;
        TotalSupply += coefficient;
        BalanceOf[msg.sender] += coefficient;
        emit StakeDay(msg.sender, amount, key);
    }

    function stake(uint256 amount) external nonReentrant onStart {
        Account memory account = Voucher[msg.sender];
        if (account.amount == 0) {
            account.account = msg.sender;
            // n+1
            uint256 start = DayRewards.length + 1;
            account.start = start;
        }
        account.amount += amount;
        account.total += amount;

        require(account.start >= DayRewards.length, "You need to collect all rewards first");
        require(IERC20(StakingToken).transferFrom(msg.sender, address(this), amount), "transfer error");
        Voucher[msg.sender] = account;
        TotalSupply += amount;
        BalanceOf[msg.sender] += amount;
        emit Stake(msg.sender, amount);
    }

    function notifyRewards() external onlyOwner {
        uint256 len = DayRewards.length;
        uint256 time = len > 0 ? DayRewards[len - 1].timestamp : StartTime;
        uint256 day = (block.timestamp - time) / 1 days;
        day = Math.min(day, 5);
        if (day > 0) {
            //todo prizePoolAddress
            uint256 amount = 111;
            for (uint256 index = 0; index < day; index++) {
                time += 1 days;
                Rewards memory rewards = Rewards({
                    amount: amount,
                    totalStaking: TotalSupply,
                    timestamp: time
                });
                TotalRewards += amount;
                DayRewards.push(rewards);
                emit NotifyRewards(DayRewards.length, amount,TotalSupply,time);
            }
           
        }
    }

    function getDayRewards(uint256 key) external nonReentrant {
        Account memory account = DayVoucher[key];
        uint256 start = _reward(account);
        account.start = start;
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
        require(amount > 0 && account.amount > amount,"");
        TotalSupply -= amount;
        BalanceOf[msg.sender] -= amount;

        account.amount -= amount;
        account.total -= amount;
        Voucher[msg.sender] = account;
        IERC20(StakingToken).transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function withdrawDay(uint256 key) external nonReentrant {
        Account memory account = DayVoucher[key];
        require(account.amount > 0, " ");
        require(block.timestamp < account.unlockTime, " ");
        TotalSupply -= account.total;
        BalanceOf[msg.sender] -= account.total;
        uint256 amount = account.amount;
        account.amount = 0;
        account.total = 0;
        DayVoucher[key] = account;
        IERC20(StakingToken).transfer(account.account, amount);
        emit WithdrawDay(msg.sender, amount,key);
    }

    function _reward(Account memory account) internal returns (uint256) {
        require(account.account == msg.sender && account.amount > 0, "");
        uint256 len = Math.min(DayRewards.length, account.start + 20);
        uint256 start = account.start;
        uint256 amount = 0;
        for (; start < len; start++) {
            Rewards memory rewards = DayRewards[start];
            uint256 total = account.total * rewards.amount;
            if(total > rewards.totalStaking){
                amount += total / rewards.totalStaking;
            }
        }
        TotalRewards -= amount;
        // todo erc20 address
        require(
            IERC20(address(0)).transfer(account.account, amount),
            "transfer error"
        );
        return start;
    }

}
