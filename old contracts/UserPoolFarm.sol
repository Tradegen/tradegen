pragma solidity >=0.5.0;

//Interfaces
import './interfaces/IPool.sol';
import './interfaces/ITradegen.sol';
import './interfaces/IUserPoolFarm.sol';

//Libraries
import './libraries/SafeMath.sol';

//Inheritance
import './Ownable.sol';

contract UserPoolFarm is IUserPoolFarm, Ownable {
    using SafeMath for uint;

    ITradegen public immutable TRADEGEN;
    address private _poolManagerAddress;

    RewardRate[] public rewardsRateHistory; //Stores previous reward rates and the timestamp each rate was changed
    uint public weeklyRewardsRate;
    uint public cumulativeSupply;

    mapping (address => PoolState) public poolStates;
    mapping (address => mapping (address => UserState)) public userStates; //pool->user->state
    mapping (address => address[]) public userInvestedPools;

    constructor(ITradegen baseTradegen, address poolManagerAddress) public Ownable() {
        TRADEGEN = baseTradegen;
        _poolManagerAddress = poolManagerAddress;
        rewardsRateHistory.push(RewardRate(uint128(block.timestamp), 0));
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Given a pool address, returns the number of LP tokens staked in the pool
    * @param poolAddress Address of the pool
    * @return uint Circulating supply of the pool
    */
    function getCirculatingSupply(address poolAddress) external view override returns (uint) {
        require(poolAddress != address(0), "Invalid pool address");
        require(poolStates[poolAddress].validPool, "Invalid pool address");

        return poolStates[poolAddress].circulatingSupply;
    }

    /**
    * @dev Given a pool address, returns the weekly rewards rate of the pool
    *      Pool reward rate is proportional to pool's share of cumulative supply
    * @param poolAddress Address of the pool
    * @return uint The weekly rewards rate of the pool
    */
    function getWeeklyRewardsRate(address poolAddress) external view override returns (uint) {
        require(poolAddress != address(0), "Invalid pool address");
        require(poolStates[poolAddress].validPool, "Invalid pool address");

        return _calculatePoolWeeklyRewardRate(poolAddress);
    }

    /**
    * @dev Given a user address and a pool address, returns the number of LP tokens the user has staked in the pool
    * @param account Address of user
    * @param poolAddress Address of the pool
    * @return uint The number of LP tokens the user staked in the pool
    */
    function balanceOf(address account, address poolAddress) public view override returns (uint) {
        require(account != address(0), "Invalid account address");
        require(poolAddress != address(0), "Invalid pool address");
        require(poolStates[poolAddress].validPool, "Invalid pool address");

        return userStates[poolAddress][account].balance;
    }

    /**
    * @dev Returns the addresses of pools the user is invested in
    * @return address[] The addresses of pools the user is invested in
    */
    function getUserInvestedPools() external view override returns (address[] memory) {
        return userInvestedPools[msg.sender];
    }

    /**
    * @dev Given a pool address, returns the available yield the user has for the pool
    * @param poolAddress Address of the pool
    * @return uint The amount of TGEN yield the user has available for the pool
    */
    function getAvailableYieldForPool(address poolAddress) external view override returns (uint) {
        require(poolAddress != address(0), "Invalid pool address");
        require(poolStates[poolAddress].validPool, "Invalid pool address");

        return _calculateAvailableYield(msg.sender, poolAddress);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @dev Stakes the specified amount of LP tokens into the given pool
    * @param poolAddress Address of the pool
    * @param amount The number of LP tokens to stake in the pool
    */
    function stake(address poolAddress, uint amount) external override {
        require(amount > 0, "Cannot stake 0");
        require(poolAddress != address(0), "Invalid pool address");
        require(poolStates[poolAddress].validPool, "Invalid pool address");

        //Number of LP tokens the user has in the pool
        uint balanceInUserPool = IPool(poolAddress).getUserTokenBalance(msg.sender);
        uint numberOfTokensAvailableToStake = balanceInUserPool.sub(uint256(userStates[poolAddress][msg.sender].balance));

        require(numberOfTokensAvailableToStake >= amount, "Not enough funds in user pool");

        userStates[poolAddress][msg.sender].timestamp = uint32(block.timestamp);
        userStates[poolAddress][msg.sender].leftoverYield = uint104(_calculateAvailableYield(msg.sender, poolAddress));
        userStates[poolAddress][msg.sender].balance = uint104(uint256(userStates[poolAddress][msg.sender].balance).add(amount));
        userStates[poolAddress][msg.sender].lastClaimIndex = uint16(rewardsRateHistory.length - 1);
        
        poolStates[poolAddress].circulatingSupply = uint128(uint256(poolStates[poolAddress].circulatingSupply).add(amount));

        cumulativeSupply.add(amount);

        //Add poolAddress to user's invested pool array if poolAddress is not already included
        uint index;
        address[] storage pools = userInvestedPools[msg.sender];
        for (index = 0; index < pools.length; index++)
        {
            if (pools[index] == poolAddress)
            {
                break;
            }
        }

        if (index == pools.length)
        {
            pools.push(poolAddress);
        }

        emit Staked(msg.sender, poolAddress, amount, block.timestamp);
    }

    /**
    * @dev Unstakes the specified amount of LP tokens from the given pool
    * @param poolAddress Address of the pool
    * @param amount The number of LP tokens to unstake from the pool
    */
    function unstake(address poolAddress, uint amount) external override {
        require(amount > 0, "Cannot withdraw 0");
        require(poolAddress != address(0), "Invalid pool address");
        require(poolStates[poolAddress].validPool, "Invalid pool address");

        uint balance = uint256(userStates[poolAddress][msg.sender].balance);

        require(balance >= amount, "Not enough funds");

        poolStates[poolAddress].circulatingSupply = uint128(uint256(poolStates[poolAddress].circulatingSupply).sub(amount));

        userStates[poolAddress][msg.sender].balance = uint104(uint256(balance).sub(amount));

        cumulativeSupply.sub(amount);

        //remove poolAddress from user's invested pools if user has 0 balance left
        if (amount == balance)
        {
            uint index;
            for (index = 0; index < userInvestedPools[msg.sender].length; index++)
            {
                if (poolAddress == userInvestedPools[msg.sender][index])
                {
                    break;
                }
            }

            userInvestedPools[msg.sender][index] = userInvestedPools[msg.sender][userInvestedPools[msg.sender].length - 1];
            userInvestedPools[msg.sender].pop();
        }

        //Claim all available yield on behalf of the user
        _claimRewards(msg.sender, poolAddress, _calculateAvailableYield(msg.sender, poolAddress));

        emit Unstaked(msg.sender, poolAddress, amount, block.timestamp);
    }

    /**
    * @dev Claims all available yield for the user in the specified pool
    * @param poolAddress Address of the pool
    */
    function claimRewards(address poolAddress) external override {
        require(poolAddress != address(0), "Invalid pool address");
        require(poolStates[poolAddress].validPool, "Invalid pool address");

        _claimRewards(msg.sender, poolAddress, _calculateAvailableYield(msg.sender, poolAddress));
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
    * @dev Given a user address and a pool address, returns the available yield the user has for the pool
    * @param user The user to calculate available yield for
    * @param poolAddress Address of the pool
    * @return uint The amount of TGEN yield the user has available for the pool
    */
    function _calculateAvailableYield(address user, address poolAddress) internal view returns (uint) {
        if (userStates[poolAddress][user].timestamp == 0)
        {
            return 0;
        }

        //Account for changes in rewards rate
        uint cumulativeRawYield = 0;
        uint timestampDelta = 0;
        for (uint i = uint256(userStates[poolAddress][user].lastClaimIndex); i < rewardsRateHistory.length - 2; i++)
        {
            timestampDelta = uint256(rewardsRateHistory[i + 1].timestamp).sub(rewardsRateHistory[i].timestamp);
            cumulativeRawYield = cumulativeRawYield.add(timestampDelta.mul(uint256(rewardsRateHistory[i].weeklyRewardsRate)));
        }

        //Account for the current rewards rate
        timestampDelta = block.timestamp.sub(uint256(userStates[poolAddress][user].timestamp));
        cumulativeRawYield.add(timestampDelta.mul(uint256(rewardsRateHistory[rewardsRateHistory.length - 1].weeklyRewardsRate)));

        //Multiply by ratio of user's balance in the pool to the cumulative supply
        uint newYield = cumulativeRawYield.mul(uint256(userStates[poolAddress][user].balance)).div(7 days).div(cumulativeSupply);

        return uint256(userStates[poolAddress][user].leftoverYield).add(newYield);
    }

    /**
    * @dev Claims rewards on behalf of the user for the given pool, based on the specified number of LP tokens
    * @param user The user to claim rewards for
    * @param poolAddress Address of the pool
    * @param amount Number of LP tokens
    */
    function _claimRewards(address user, address poolAddress, uint amount) internal {
        userStates[poolAddress][user].leftoverYield = uint104(_calculateAvailableYield(user, poolAddress).sub(amount));
        userStates[poolAddress][user].timestamp = uint32(block.timestamp);
        userStates[poolAddress][user].lastClaimIndex = uint16(rewardsRateHistory.length - 1);
        TRADEGEN.sendRewards(user, amount);

        emit ClaimedRewards(user, poolAddress, amount, block.timestamp);
    }

    /**
    * @dev Calculates the weekly rewards rate for the given pool
    * @param poolAddress Address of the pool
    */
    function _calculatePoolWeeklyRewardRate(address poolAddress) internal view returns (uint) {
        require(poolAddress != address(0), "Invalid pool address");
        require(poolStates[poolAddress].validPool, "Invalid pool address");

        uint poolSupply = uint256(poolStates[poolAddress].circulatingSupply);

        //Ratio of pool's circulating supply to cumulative supply across all pools
        return poolSupply.mul(uint256(rewardsRateHistory[rewardsRateHistory.length - 1].weeklyRewardsRate)).div(cumulativeSupply);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @dev Updates the weekly rewards rate; meant to be called by the contract owner
    * @param newWeeklyRewardsRate The new weekly rewards rate
    */
    function updateWeeklyRewardsRate(uint newWeeklyRewardsRate) public override onlyOwner {
        require(newWeeklyRewardsRate >= 0, "Weekly rewards rate cannot be negative");

        rewardsRateHistory.push(RewardRate(uint128(block.timestamp), uint128(newWeeklyRewardsRate)));

        emit UpdatedWeeklyRewardsRate(newWeeklyRewardsRate, block.timestamp);
    }

    /**
    * @dev Initializes the PoolState for the given pool
    * @param poolAddress Address of the pool
    */
    function initializePool(address poolAddress) public override onlyPoolManager {
        require(poolAddress != address(0), "Invalid pool address");
        require(!poolStates[poolAddress].validPool, "Pool already exists");

        poolStates[poolAddress] = PoolState(0, 0, true);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyPoolManager() {
        require(msg.sender == _poolManagerAddress, "Only the PoolManager contract can call this function");
        _;
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed user, address indexed poolAddress, uint amount, uint timestamp);
    event Unstaked(address indexed user, address indexed poolAddress, uint amount, uint timestamp);
    event ClaimedRewards(address indexed user, address indexed poolAddress, uint amount, uint timestamp);
    event UpdatedWeeklyRewardsRate(uint newWeeklyRewardsRate, uint timestamp);
}