//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./swap/IUniswapV2Factory.sol";
import "./swap/IUniswapV2Router.sol";
import "./swap/IUniswapV2Pair.sol";

contract IdoCoreV1 is Ownable {
    using Math for uint256;
    //100 day
    uint256 public constant PERIOD_FINISH = 8640000;

    mapping(address => uint256) public BalanceOf;
    uint256 public TotalSupply;
    address public StakingToken;
    address public RewardsToken;
    IUniswapV2Router public immutable Router;

    uint256 public Deadline;

    uint256 public TotalLP;

    uint256 public SecondRewards;

    uint256 public SecondLP;

    uint256 public SecondStaking;

    mapping(address => uint256) ReceivedLast;

    event Stake(address indexed staker, uint256 amount);

    event RewardPaid(
        address indexed account,
        uint256 rewardStaking,
        uint256 rewardToken
    );

    event Test(uint256 indexed amount1, uint256 indexed amount2);
    modifier OnStake() {
        require(block.timestamp < Deadline, "Cannot be performed stake");
        _;
    }

    modifier OnReward() {
        require(block.timestamp > Deadline, "Cannot be performed reward");
        _;
    }

    constructor(
        address _stakingToken,
        address _rewardsToken,
        address _router,
        uint256 _deadline
    ) {
        StakingToken = _stakingToken;
        RewardsToken = _rewardsToken;
        Router = IUniswapV2Router(_router);
        Deadline = _deadline;
    }

    //延长时间
    function setDeadline(uint256 deadline) external onlyOwner {
        if (deadline == 0) {
            Deadline = deadline;
        } else {
            require(block.timestamp < Deadline, "Cannot be performed stake");
            Deadline = deadline;
        }
    }

    function stake(uint256 amount) external OnStake {
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
        IERC20(RewardsToken).approve(address(Router), rewards * 10);
        IERC20(StakingToken).approve(address(Router), staking * 10);
        (uint256 amount0, uint256 amount1, uint256 liquidity) = Router
            .addLiquidity(
                StakingToken,
                RewardsToken,
                TotalSupply,
                rewards,
                1,
                1,
                address(this),
                block.timestamp
            );
        (address tokenA, ) = sortTokens(StakingToken, RewardsToken);
        (uint256 amountStaking, uint256 amountRewards) = tokenA == StakingToken
            ? (amount0, amount1)
            : (amount1, amount0);
        address pair = pairFor(StakingToken, RewardsToken);
        IUniswapV2Pair(pair).approve(address(Router), liquidity * 10);

        TotalLP += liquidity;

        // per second
        SecondRewards += (amountRewards * 1e18) / PERIOD_FINISH / amountStaking;
        SecondLP += (liquidity * 1e18) / PERIOD_FINISH / amountStaking;
        SecondStaking += 1e18 / PERIOD_FINISH;
    }

    function rewardTime(address account) public view returns (uint256) {
        return
            Math.min(block.timestamp - Deadline, PERIOD_FINISH) -
            ReceivedLast[account];
    }

    // function totalLPOf(address account) public view returns (uint256) {
    //     return ((BalanceOf[account] * 1e18) / TotalSupply) * TotalLP;
    // }

    function getReward() external OnReward {
        uint256 time = rewardTime(msg.sender);
        uint256 balance = time * BalanceOf[msg.sender];
        uint256 liquidity = (SecondLP * balance) / 1e18;

        emit Test(balance, liquidity);
        require(liquidity > 0, "Low liquidity");
        (uint256 amount0, uint256 amount1) = Router.removeLiquidity(
            StakingToken,
            RewardsToken,
            liquidity,
            1,
            1,
            address(this),
            block.timestamp
        );
        (address tokenA, ) = sortTokens(StakingToken, RewardsToken);
        (uint256 amountStaking, uint256 amountRewards) = tokenA == StakingToken
            ? (amount0, amount1)
            : (amount1, amount0);
        uint256 amountAccount = (SecondStaking * balance) / 1e18;
        uint256 stakingBalance = IERC20(StakingToken).balanceOf(address(this));

        if (amountStaking > stakingBalance) {
            amountStaking = stakingBalance;
        }
        IERC20(StakingToken).transfer(msg.sender, amountStaking);
        uint256 give = 0;
        if (amountStaking > amountAccount) {
            // IERC20(RewardsToken).transfer(address(1), amountRewards);
            give = 1;
        } else if (amountStaking == amountAccount) {
            give = 2;
        } else {
            give = 3;
            // give = amountRewards - ((SecondRewards * balance) / 1e18);
            // IERC20(RewardsToken).transfer(msg.sender, give);
            // IERC20(RewardsToken).transfer(address(1), amountRewards - give);
        }
        // emit Test(amountAccount, amountStaking);
        ReceivedLast[msg.sender] += time;
        emit RewardPaid(msg.sender, amountStaking, give);
        emit Test(give, amountRewards);
    }

    function pairFor(address tokenA, address tokenB)
        public
        view
        returns (address pair)
    {
        pair = IUniswapV2Factory(Router.factory()).getPair(tokenA, tokenB);
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "SWAP: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "SWAP: ZERO_ADDRESS");
    }
}
