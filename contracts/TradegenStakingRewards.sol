// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// Libraries.
import "./openzeppelin-solidity/SafeMath.sol";
import "./openzeppelin-solidity/SafeERC20.sol";

// Interfaces.
import './interfaces/IAddressResolver.sol';
import './interfaces/ISettings.sol';
import './interfaces/ITradegenStakingEscrow.sol';

// Inheritance.
import './interfaces/Ubeswap/IStakingRewards.sol';
import "./openzeppelin-solidity/ReentrancyGuard.sol";
import "./Ownable.sol";

contract TradegenStakingRewards is IStakingRewards, ReentrancyGuard, Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IAddressResolver public immutable ADDRESS_RESOLVER;

    // TGEN token.
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

    /**
    * @notice Returns the address of the staking token.
    */
    function stakingToken() external view override returns (address) {
        return address(STAKING_TOKEN);
    }

    /**
    * @notice Returns the address of the rewards token.
    */
    function rewardsToken() external view override returns (address) {
        return address(STAKING_TOKEN);
    }

    /**
    * @notice Returns the total amount of tokens staked.
    */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
    * @notice Returns the number of tokens the user has staked.
    * @param account Address of the user.
    */
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    /**
    * @notice Returns the latest timestamp to use when calculating pending rewards.
    */
    function lastTimeRewardApplicable() public view override returns (uint256) {
        return (block.timestamp < periodFinish) ? block.timestamp : periodFinish;
    }

    /**
    * @notice Returns the amount of reward tokens to distribute per staking token.
    */
    function rewardPerToken() public view override returns (uint256) {
        if (_totalSupply == 0)
        {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored.add(lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply));
    }

    /**
    * @notice Returns the amount of rewards the user has available.
    * @param account Address of the user.
    */
    function earned(address account) public view override returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    /**
    * @notice Returns the total number of reward tokens that will be distributed.
    */
    function getRewardForDuration() external view override returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Stakes tokens and updates available rewards.
    * @param amount Number of tokens to stake.
    */
    function stake(uint256 amount) external override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "TradegenStakingRewards: Cannot stake 0.");

        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        STAKING_TOKEN.safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount);
    }

    /**
    * @notice Withdraws the given amount of tokens and claims any available rewards.
    * @dev Throws an error if the user tries to withdraw more than their balance.
    */
    function withdraw(uint256 amount) public override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "TradegenStakingRewards: Cannot withdraw 0.");

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        STAKING_TOKEN.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    /**
    * @notice Claims available rewards for the user.
    */
    function getReward() external override nonReentrant {
        _claim(msg.sender);
    }

    /**
    * @notice Withdraws the user's full stake and claims rewards.
    */
    function exit() external override {
        _claim(msg.sender);
        withdraw(_balances[msg.sender]);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
    * @notice Claims available rewards for the user.
    */
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

    /**
    * @notice Sets the reward amount for the next period.
    * @dev Only the protocol owner can call this function.
    * @dev The current reward period must finish before this function can be called.
    * @dev Throws an error if the escrow contract does not have enough tokens.
    * @param reward Amount of reward tokens to distribute in the next period.
    */
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
        require(rewardRate <= balance.div(rewardsDuration), "TradegenStakingRewards: Provided reward too high.");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    /**
    * @notice Ends reward emissions at the given timestamp.
    * @dev Only the protocol owner can call this function.
    * @param _timestamp The timestamp at which the reward period will finish.
    */
    function updatePeriodFinish(uint _timestamp) external onlyOwner updateReward(address(0)) {
        periodFinish = _timestamp;
    }

    /**
    * @notice Updates the reward duration.
    * @dev Only the protocol owner can call this function.
    * @dev Throws an error if the current reward period has not finished.
    * @param _rewardsDuration The new reward duration.
    */
    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "TradegenStakingRewards: Previous rewards period must be complete before changing the duration for the new period."
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