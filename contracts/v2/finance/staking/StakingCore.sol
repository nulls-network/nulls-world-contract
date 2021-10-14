//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../interfaces/INullsBigPrizePool.sol";

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
    }

    INullsBigPrizePool public PrizePool;
    address public RewardsToken;
    uint256 public PrizePoolIndex;
    address public StakingToken;

    uint256 public StartTime;

    uint256 public TotalSupply;

    uint256 public TotalRewards;

    mapping(address => uint256) public BalanceOf;

    mapping(address => Account) public Voucher;

    mapping(uint256 => Account) public DayVoucher;

    mapping(uint256 => uint256) public Coefficient;

    Rewards[] public DayRewards;

    event Stake(address indexed account, uint256 amount);
    event StakeDay(address indexed account, uint256 amount,uint256 key);
    event Withdraw(address indexed account, uint256 amount);
    event WithdrawDay(address indexed account, uint256 amount, uint256 key);
    event SetCoefficient(uint256 indexed time, uint256 coefficient);
    event NotifyRewards(uint256 indexed index, uint256 rewards,uint256 totalStaking);
    constructor(
        uint256 _startTime,
        address _stakingToken,
        address _prizePool
    ) {
        StartTime = _startTime;
        StakingToken = _stakingToken;
        PrizePool = INullsBigPrizePool(_prizePool);
        RewardsToken = PrizePool.TokenAddr();
    }

    modifier onStart() {
        require(block.timestamp > StartTime, "The event has not yet started");
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

    function dayRewardsLength() public view returns(uint256) {
        return DayRewards.length;
    }

    function stakeDay(uint256 time, uint256 amount)  external nonReentrant onStart{
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
        if(PrizePoolIndex == 0){
            //todo update
            // PrizePoolIndex=INullsBigPrizePool(PrizePool);
        }
        uint256 index = PrizePoolIndex;
        uint256 len = Math.min(index + 10, PrizePool.DayIndex());
        require(index < len, "No rewards available");
        for (; index < len; index++) {
            (uint8 code,uint256 amount) = PrizePool.transferOut(index);
            //todo code error
            Rewards memory rewards = Rewards({
                amount: amount,
                totalStaking: TotalSupply
            });
            TotalRewards += amount;
            DayRewards.push(rewards);
            emit NotifyRewards(DayRewards.length, amount,TotalSupply);
        }
        PrizePoolIndex = index;
        
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
        require(amount > 0 && account.amount > amount,"Wrong amount withdrawn");
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
        require(account.account== msg.sender,"The amount does not belong to you");
        require(account.amount > 0, "The amount has been withdrawn");
        require(block.timestamp < account.unlockTime, "Lockout time is not over");
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
        require(account.account == msg.sender, "The reward does not belong to you");
        uint256 len = Math.min(DayRewards.length, account.start + 20);
        uint256 start = account.start;
         require(start == len && account.amount > 0, "Cannot collect rewards");
        uint256 amount = 0;
        for (; start < len; start++) {
            Rewards memory rewards = DayRewards[start];
            uint256 total = account.total * rewards.amount;
            if(total > rewards.totalStaking){
                amount += total / rewards.totalStaking;
            }
        }
        TotalRewards -= amount;
        require(
            IERC20(RewardsToken).transfer(account.account, amount),
            "transfer error"
        );
        return start;
    }

}
