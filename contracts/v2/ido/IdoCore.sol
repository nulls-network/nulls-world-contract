//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./swap/interface/IUniswapV2Factory.sol";
import "./swap/interface/IUniswapV2Pair.sol";
import "./swap/SwapRouter.sol";

contract IdoCore is Ownable, SwapRouter, ReentrancyGuard {
    using Math for uint256;
    //100 day
    uint256 public constant REWARDS_FINISH = 8640000;

    mapping(address => uint256) public BalanceOf;

    uint256 public TotalSupply;
    address public StakingToken;
    address public RewardsToken;
    uint256 public PeriodFinish;
    uint256 public Destroy;
    uint256 public TotalLP;

    mapping(address => uint256) ReceivedLast;

    event Stake(address indexed staker, uint256 amount);

    event RewardPaid(
        address indexed account,
        uint256 rewardStaking,
        uint256 rewardToken
    );

    modifier OnStake() {
        require(block.timestamp < PeriodFinish, "Cannot be performed stake");
        _;
    }

    modifier OnReward() {
        require(block.timestamp > PeriodFinish, "Cannot be performed reward");
        _;
    }

    constructor(
        address _stakingToken,
        address _rewardsToken,
        address _factory,
        uint256 _periodFinish
    ) SwapRouter(_factory) {
        StakingToken = _stakingToken;
        RewardsToken = _rewardsToken;
        PeriodFinish = _periodFinish > block.timestamp ? _periodFinish : 0;
    }

    function setPeriodFinish(uint256 periodFinish) external onlyOwner {
        require(periodFinish > 0, 'Cannot be zero');
        if (PeriodFinish == 0) {
            PeriodFinish = periodFinish;
        } else {
            require(
                block.timestamp < PeriodFinish,
                "Cannot be performed stake"
            );
            PeriodFinish = periodFinish;
        }
    }

    function stake(uint256 amount) external nonReentrant OnStake {
        require(
            IERC20(StakingToken).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "transfer error"
        );
        BalanceOf[msg.sender] += amount;
        TotalSupply += amount;
        emit Stake(msg.sender, amount);
    }

    function addLiquidity() external OnReward onlyOwner {
        uint256 rewards = IERC20(RewardsToken).balanceOf(address(this));
        uint256 staking = IERC20(StakingToken).balanceOf(address(this));
        if (staking > TotalSupply) {
            //todo
        }
        (, , uint256 liquidity) = _safeAddLiquidity(
            StakingToken,
            RewardsToken,
            TotalSupply,
            rewards,
            1,
            1,
            block.timestamp
        );
        Destroy += rewards / REWARDS_FINISH;
        TotalLP += liquidity;
    }

    function getReward() external nonReentrant OnReward {
        uint256 time = rewardTime(msg.sender);
        uint256 rate = rateOf(msg.sender);
        uint256 liquidity = rate * TotalLP;
        require(liquidity >= 0x989680, "Insufficient liquidity");
        liquidity /= 0x989680;
        (uint256 amount0, uint256 amount1) = _safeRemoveLiquidity(
            StakingToken,
            RewardsToken,
            liquidity,
            1,
            1,
            block.timestamp
        );
        (address tokenA, ) = sortTokens(StakingToken, RewardsToken);
        (uint256 amountStaking, uint256 amountRewards) = tokenA == StakingToken
            ? (amount0, amount1)
            : (amount1, amount0);
        uint256 amountAccount = (rate * BalanceOf[msg.sender]) / 0x989680;
        uint256 stakingBalance = IERC20(StakingToken).balanceOf(address(this));

        if (amountStaking > stakingBalance) {
            amountStaking = stakingBalance;
        }
        IERC20(StakingToken).transfer(msg.sender, amountStaking);

        if (amountStaking < amountAccount) {
            uint256 destroyAmount = Destroy * time;
            if (amountRewards > destroyAmount) {
                uint256 give = ((amountRewards - destroyAmount) * rate) / 0x989680;
                IERC20(RewardsToken).transfer(msg.sender, give);
            }
        }
        ReceivedLast[msg.sender] += time;
        emit RewardPaid(msg.sender, amountStaking, liquidity);
    }

    function rateOf(address account) public view returns (uint256) {
        uint256 time = rewardTime(account);
        uint256 balanceRate = (BalanceOf[account] * 0x989680) / TotalSupply;
        return (balanceRate * time) / REWARDS_FINISH;
    }

    function rewardTime(address account) public view returns (uint256) {
        return
            Math.min(block.timestamp - PeriodFinish, REWARDS_FINISH) -
            ReceivedLast[account];
    }
}
