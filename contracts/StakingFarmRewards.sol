// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

//Libraries
import './libraries/SafeMath.sol';

//Interfaces
import './interfaces/IERC20.sol';
import './interfaces/IAddressResolver.sol';
import './interfaces/ISettings.sol';
import './interfaces/IBaseUbeswapAdapter.sol';
import './interfaces/Ubeswap/IStakingRewards.sol';

//Inheritance
import './interfaces/IStakingFarmRewards.sol';
import "./openzeppelin-solidity/ReentrancyGuard.sol";
import "./Ownable.sol";

contract StakingFarmRewards is IStakingFarmRewards, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    IAddressResolver public immutable ADDRESS_RESOLVER;

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

    constructor(IAddressResolver _addressResolver) Ownable() {
        ADDRESS_RESOLVER = _addressResolver;
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

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount, address farm) external override nonReentrant updateReward(msg.sender, farm) {
        require(amount > 0, "Cannot stake 0");

        address stakingToken = IStakingRewards(farm).stakingToken();

        _totalSupply[farm] = _totalSupply[farm].add(amount);
        _balances[farm][msg.sender] = _balances[farm][msg.sender].add(amount);
        IERC20(stakingToken).transferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, farm, amount, block.timestamp);
    }

    function withdraw(uint256 amount, address farm) public override nonReentrant updateReward(msg.sender, farm) {
        require(amount > 0, "Cannot withdraw 0");

        address stakingToken = IStakingRewards(farm).stakingToken();

        _totalSupply[farm] = _totalSupply[farm].sub(amount);
        _balances[farm][msg.sender] = _balances[farm][msg.sender].sub(amount);
        IERC20(stakingToken).transfer(msg.sender, amount);

        emit Withdrawn(msg.sender, farm, amount, block.timestamp);
    }

    function getReward(address farm) public override nonReentrant updateReward(msg.sender, farm) {
        uint256 reward = rewards[farm][msg.sender];
        address TGEN = ADDRESS_RESOLVER.getContractAddress("TradegenERC20");

        if (reward > 0)
        {
            rewards[farm][msg.sender] = 0;
            IERC20(TGEN).transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, farm, reward, block.timestamp);
        }
    }

    function exit(address farm) external override {
        withdraw(_balances[farm][msg.sender], farm);
        getReward(farm);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward) external onlyOwner updateReward(address(0), address(0)) {
        address TGEN = ADDRESS_RESOLVER.getContractAddress("TradegenERC20");

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
        uint balance = IERC20(TGEN).balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        address baseUbeswapAdapterAddress = ADDRESS_RESOLVER.getContractAddress("BaseUbeswapAdapter");
        address[] memory farms = IBaseUbeswapAdapter(baseUbeswapAdapterAddress).getAvailableUbeswapFarms();
        for (uint i = 0; i < farms.length; i++)
        {
            lastUpdateTime[farms[i]] = block.timestamp;
        }

        numberOfFarms = numberOfFarms.add(farms.length);

        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward, block.timestamp);
    }

    /**
     * @notice Adds a new farm for staking
     */
    function addFarm(address farm) external onlyOwner {
        require(farm != address(0), "Invalid farm address");
        require(lastUpdateTime[farm] > 0, "Farm already exists");

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
            }
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward, uint timestamp);
    event Staked(address indexed user, address indexed farm, uint256 amount, uint timestamp);
    event Withdrawn(address indexed user, address indexed farm, uint256 amount, uint timestamp);
    event RewardPaid(address indexed user, address indexed farm, uint256 reward, uint timestamp);
    event AddedFarm(address farm, uint timestamp);
    event InitializedFarms(uint numberOfFarmsAdded, uint timestamp);
}