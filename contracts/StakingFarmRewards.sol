// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//Libraries
import "./openzeppelin-solidity/SafeMath.sol";
import "./openzeppelin-solidity/SafeERC20.sol";

//Interfaces
import './interfaces/IAddressResolver.sol';
import './interfaces/ISettings.sol';
import './interfaces/ILPVerifier.sol';
import './interfaces/Ubeswap/IStakingRewards.sol';

//Inheritance
import './interfaces/IStakingFarmRewards.sol';
import "./openzeppelin-solidity/ReentrancyGuard.sol";
import "./Ownable.sol";

contract StakingFarmRewards is IStakingFarmRewards, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IAddressResolver public immutable ADDRESS_RESOLVER;

    // TGEN
    IERC20 public immutable REWARD_TOKEN;

    IERC20 public immutable EXTERNAL_REWARD_TOKEN;

    mapping (address => mapping(address => uint256)) public externalRewards;
    mapping (address => mapping(address => uint256)) public externalUserRewardPerTokenPaid;
    mapping (address => uint256) public externalRewardPerTokenStored;

    uint256 public override periodFinish = 0;
    uint256 public override rewardRate = 0;
    uint256 public rewardsDuration = 7 days;
    mapping (address => uint256) public lastUpdateTime;
    mapping (address => uint256) public rewardPerTokenStored;

    mapping (address => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping (address => mapping(address => uint256)) public rewards;

    mapping (address => uint256) private _totalSupply;
    mapping (address => mapping(address => uint256)) private _balances;

    uint public numberOfFarms;

    /* ========== CONSTRUCTOR ========== */

    constructor(IAddressResolver _addressResolver, address _externalRewardToken, address _rewardToken) Ownable() {
        require(_externalRewardToken != address(0), "StakingFarmRewards: invalid external reward token");

        ADDRESS_RESOLVER = _addressResolver;
        EXTERNAL_REWARD_TOKEN = IERC20(_externalRewardToken);
        REWARD_TOKEN = IERC20(_rewardToken);
    }

    /* ========== VIEWS ========== */

    function totalSupply(address farm) external view override returns (uint256) {
        return _totalSupply[farm];
    }

    function balanceOf(address account, address farm) external view override returns (uint256) {
        return _balances[farm][account];
    }

    function lastTimeRewardApplicable() public view override returns (uint256) {
        return (block.timestamp < periodFinish) ? block.timestamp : periodFinish;
    }

    function rewardPerToken(address farm) public view override returns (uint256) {
        if (_totalSupply[farm] == 0)
        {
            return rewardPerTokenStored[farm];
        }

        return rewardPerTokenStored[farm].add(lastTimeRewardApplicable().sub(lastUpdateTime[farm]).mul(rewardRate).mul(1e18).div(_totalSupply[farm])).div(numberOfFarms);
    }

    function earned(address account, address farm) public view override returns (uint256) {
        return _balances[farm][account].mul(rewardPerToken(farm).sub(userRewardPerTokenPaid[farm][account])).div(1e18).add(rewards[farm][account]);
    }

    function getRewardForDuration() external view override returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    function earnedExternal(address account, address farm) public returns (uint result) {
        uint externalOldTotalRewards = EXTERNAL_REWARD_TOKEN.balanceOf(address(this));

        IStakingRewards(farm).getReward();

        uint externalTotalRewards = EXTERNAL_REWARD_TOKEN.balanceOf(address(this));
        uint newExternalRewardsAmount = externalTotalRewards.sub(externalOldTotalRewards);

        if (_totalSupply[farm] > 0)
        {
            externalRewardPerTokenStored[farm] = externalRewardPerTokenStored[farm].add(newExternalRewardsAmount.mul(1e18).div(_totalSupply[farm]));
        }

        result = _balances[farm][account]
                .mul(externalRewardPerTokenStored[farm].sub(externalUserRewardPerTokenPaid[farm][account]))
                .div(1e18).add(externalRewards[farm][account]);

        externalUserRewardPerTokenPaid[farm][account] = externalRewardPerTokenStored[farm];
        externalRewards[farm][account] = result;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount, address farm) external override nonReentrant updateReward(msg.sender, farm) {
        require(amount > 0, "Cannot stake 0");

        address ubeswapLPVerifierAddress = ADDRESS_RESOLVER.assetVerifiers(2);

        require(ubeswapLPVerifierAddress != address(0), "StakingFarmRewards: invalid UbeswapLPVerifier address");

        (address stakingToken,) = ILPVerifier(ubeswapLPVerifierAddress).getFarmTokens(farm);

        _totalSupply[farm] = _totalSupply[farm].add(amount);
        _balances[farm][msg.sender] = _balances[farm][msg.sender].add(amount);
        IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(stakingToken).approve(farm, amount);
        IStakingRewards(farm).stake(amount);

        emit Staked(msg.sender, farm, amount, block.timestamp);
    }

    function withdraw(uint256 amount, address farm) public override nonReentrant updateReward(msg.sender, farm) {
        require(amount > 0, "Cannot withdraw 0");

        address ubeswapLPVerifierAddress = ADDRESS_RESOLVER.assetVerifiers(2);

        require(ubeswapLPVerifierAddress != address(0), "StakingFarmRewards: invalid UbeswapLPVerifier address");

        (address stakingToken,) = ILPVerifier(ubeswapLPVerifierAddress).getFarmTokens(farm);

        _totalSupply[farm] = _totalSupply[farm].sub(amount);
        _balances[farm][msg.sender] = _balances[farm][msg.sender].sub(amount);
        IStakingRewards(farm).withdraw(amount);
        IERC20(stakingToken).safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, farm, amount, block.timestamp);
    }

    function getReward(address farm) public override nonReentrant {
        _claim(msg.sender, farm);
    }

    function exit(address farm) external override {
        withdraw(_balances[farm][msg.sender], farm);
        getReward(farm);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _claim(address user, address farm) internal updateReward(user, farm) {
        uint256 reward = rewards[farm][user];
        uint256 externalReward = externalRewards[farm][user];
        address ubeswapLPVerifierAddress = ADDRESS_RESOLVER.assetVerifiers(2);

        require(ubeswapLPVerifierAddress != address(0), "StakingFarmRewards: invalid UbeswapLPVerifier address");

        (,address rewardsToken) = ILPVerifier(ubeswapLPVerifierAddress).getFarmTokens(farm);

        if (reward > 0)
        {
            rewards[farm][user] = 0;
            REWARD_TOKEN.safeTransfer(user, reward);
            emit RewardPaid(user, farm, reward, block.timestamp);
        }

        if (externalReward > 0)
        {
            externalRewards[farm][user] = 0;
            IERC20(rewardsToken).safeTransfer(user, externalReward);
            emit ExternalRewardPaid(user, farm, externalReward, block.timestamp);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) external onlyOwner updateReward(address(0), address(0)) {
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
        uint balance = REWARD_TOKEN.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward, block.timestamp);
    }

    /**
     * @notice Adds a new farm for staking
     */
    function addFarm(address farm) external onlyOwner {
        require(farm != address(0), "Invalid farm address");
        require(lastUpdateTime[farm] == 0, "Farm already exists");
        require(block.timestamp >= periodFinish, "Need to wait for period to finish before adding farm");

        lastUpdateTime[farm] = block.timestamp;
        numberOfFarms = numberOfFarms.add(1);

        emit AddedFarm(farm, block.timestamp);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account, address farm) {
        if (farm != address(0))
        {
            require(lastUpdateTime[farm] > 0, "invalid farm");

            rewardPerTokenStored[farm] = rewardPerToken(farm);
            lastUpdateTime[farm] = lastTimeRewardApplicable();

            if (account != address(0))
            {
                rewards[farm][account] = earned(account, farm);
                userRewardPerTokenPaid[farm][account] = rewardPerTokenStored[farm];
                earnedExternal(account, farm);
            }
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward, uint timestamp);
    event Staked(address indexed user, address indexed farm, uint256 amount, uint timestamp);
    event Withdrawn(address indexed user, address indexed farm, uint256 amount, uint timestamp);
    event RewardPaid(address indexed user, address indexed farm, uint256 reward, uint timestamp);
    event ExternalRewardPaid(address indexed user, address indexed farm, uint256 reward, uint timestamp);
    event AddedFarm(address farm, uint timestamp);
}