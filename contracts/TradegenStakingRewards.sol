// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//Libraries
import "./openzeppelin-solidity/SafeMath.sol";
import "./openzeppelin-solidity/SafeERC20.sol";

//Interfaces
import './interfaces/IAddressResolver.sol';
import './interfaces/ISettings.sol';
import './interfaces/ITradegenStakingEscrow.sol';

//Inheritance
import './interfaces/Ubeswap/IStakingRewards.sol';
import "./openzeppelin-solidity/ReentrancyGuard.sol";
import "./Ownable.sol";

contract TradegenStakingRewards is IStakingRewards, ReentrancyGuard, Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IAddressResolver public immutable ADDRESS_RESOLVER;

    // TGEN-CELO LP token
    IERC20 public immutable STAKING_TOKEN;

    uint256 public override periodFinish = 0;
    uint256 public override rewardRate = 0;
    uint256 public rewardsDuration = 7 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /* ========== CONSTRUCTOR ========== */

    constructor(IAddressResolver _addressResolver, address _stakingToken) Ownable() {
        ADDRESS_RESOLVER = _addressResolver;
        STAKING_TOKEN = IERC20(_stakingToken);
    }

    /* ========== VIEWS ========== */

    function stakingToken() external view override returns (address) {
        return address(STAKING_TOKEN);
    }

    function rewardsToken() external view override returns (address) {
        return address(STAKING_TOKEN);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view override returns (uint256) {
        return (block.timestamp < periodFinish) ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view override returns (uint256) {
        if (_totalSupply == 0)
        {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored.add(lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply));
    }

    function earned(address account) public view override returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view override returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");

        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        STAKING_TOKEN.safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        STAKING_TOKEN.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function getReward() external override nonReentrant {
        _claim(msg.sender);
    }

    function exit() external override {
        _claim(msg.sender);
        withdraw(_balances[msg.sender]);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _claim(address user) internal updateReward(user) {
        uint256 reward = rewards[user];
        address escrowAddress = ADDRESS_RESOLVER.getContractAddress("TradegenStakingEscrow");

        if (reward > 0)
        {
            rewards[user] = 0;
            ITradegenStakingEscrow(escrowAddress).claimStakingRewards(user, reward);
            emit RewardPaid(user, reward);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) external onlyOwner updateReward(address(0)) {
        address tradegenStakingEscrowAddress = ADDRESS_RESOLVER.getContractAddress("TradegenStakingEscrow");

        if (block.timestamp >= periodFinish)
        {
            rewardRate = reward.div(rewardsDuration);
        } 
        else
        {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = STAKING_TOKEN.balanceOf(tradegenStakingEscrowAddress);
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    // End rewards emission earlier
    function updatePeriodFinish(uint timestamp) external onlyOwner updateReward(address(0)) {
        periodFinish = timestamp;
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
}