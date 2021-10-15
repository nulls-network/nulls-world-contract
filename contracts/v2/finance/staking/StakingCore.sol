//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../../interfaces/INullsBigPrizePool.sol";

contract StakingCore is Ownable, ReentrancyGuard {
    using Math for uint256;

    //stakingAccount
    struct Account {
        uint256 amount;
        uint256 total;
        uint256 start;
        uint256 unlockTime;
        uint256 coefficient;
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


    mapping(uint256 => mapping( address => Account)) public Voucher;

    mapping(uint256 => uint256) public Coefficient;

    Rewards[] public DayRewards;

    event Staked(address indexed account, uint256 amount,uint256 time);
    event Withdraw(address indexed account, uint256 amount,uint256 time);
    event Reward(address indexed account, uint256 amount, uint256 time);
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

    function getCoefficient(uint256 time) public view returns (uint256 ) {
        if(time == 0){
            return 1000;
        }
        return Coefficient[time];
    }

    function setCoefficient(uint256 time,uint256 coefficient) external  {
         Coefficient[time] = coefficient;
         emit SetCoefficient(time,coefficient);
    }

    function dayRewardsLength() public view returns(uint256) {
        return DayRewards.length;
    }

    function stake(uint256 time, uint256 amount)  external nonReentrant onStart{
        require(amount > 0, "amount cannot 0");
        require(IERC20(StakingToken).transferFrom(msg.sender, address(this), amount), "transfer error");
        uint256 coefficient = getCoefficient(time);
        require(coefficient >= 1000, "Coefficient not exist");
        //total
        uint256 total = (amount * coefficient) / 1000;
        Account memory account= Voucher[time][msg.sender];
        if(account.amount == 0){
            account.start = DayRewards.length + 1;
        }
        require(account.start >= DayRewards.length, "You need to collect all rewards first");
        account.amount += amount;
        account.total += total;
        account.unlockTime = block.timestamp + time;
        account.coefficient = coefficient;

        Voucher[time][msg.sender] = account;
        TotalSupply += total;
        BalanceOf[msg.sender] += total;
        emit Staked(msg.sender, amount, time);   
    }

    function getReward(uint256 time) external nonReentrant {
        Account memory account = Voucher[time][msg.sender];
        uint256 len = Math.min(account.start + 20, DayRewards.length );
        uint256 start = account.start;
        require(start == len && account.amount > 0, "Cannot collect rewards");
        uint256 amount = 0;
        for (; start < len; start++) {
            Rewards memory rewards = DayRewards[start];
            uint256 reward = account.total * rewards.amount * 1e18 / rewards.totalStaking;
            if(reward > 1e18){
                amount += reward / 1e18;
            }
        }
        TotalRewards -= amount;
        require(
            IERC20(RewardsToken).transfer(msg.sender, amount),
            "transfer error"
        );
        account.start = start;
        Voucher[time][msg.sender] = account;
        emit Reward(msg.sender, amount, time);
    }


    function withdraw(uint256 time, uint256 amount) external nonReentrant {
        Account memory account = Voucher[time][msg.sender];
        require(account.amount > 0 && account.amount > amount, "Wrong amount withdrawn");
        require(block.timestamp < account.unlockTime, "Lockout time is not over");
        uint256 total= amount * account.coefficient /1000;
        TotalSupply -= total;
        BalanceOf[msg.sender] -= total;
        account.amount -= amount;
        account.total -= total;
        Voucher[time][msg.sender] = account;
        IERC20(StakingToken).transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount, time);
    }

    function notifyRewards() external onlyOwner {
        if(PrizePoolIndex == 0){
            PrizePoolIndex = PrizePool.RewardStartDayIndex(address(this))-1;
        }
        uint256 index = PrizePoolIndex;
        uint256 len = Math.min(index + 10, PrizePool.DayIndex());
        require(index < len, "No rewards available");
        for (; index < len; index++) {
            uint256 amount = PrizePool.transferOut(index);
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


}
