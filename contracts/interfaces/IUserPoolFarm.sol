pragma solidity >=0.5.0;

interface IUserPoolFarm {

    struct PoolState {
        uint128 circulatingSupply;
        uint120 weeklyRewardsRate;
        bool validPool;
    }

    struct UserState {
        uint32 timestamp;
        uint16 lastClaimIndex;
        uint104 leftoverYield;
        uint104 balance;
    }

    struct RewardRate {
        uint128 timestamp;
        uint128 weeklyRewardsRate;
    }

    /**
    * @dev Given a pool address, returns the number of LP tokens staked in the pool
    * @param poolAddress Address of the pool
    * @return uint Circulating supply of the pool
    */
    function getCirculatingSupply(address poolAddress) external view returns (uint);

    /**
    * @dev Given a pool address, returns the weekly rewards rate of the pool
    *      Pool reward rate is proportional to pool's share of cumulative supply
    * @param poolAddress Address of the pool
    * @return uint The weekly rewards rate of the pool
    */
    function getWeeklyRewardsRate(address poolAddress) external view returns (uint);

    /**
    * @dev Given a user address and a pool address, returns the number of LP tokens the user has staked in the pool
    * @param account Address of user
    * @param poolAddress Address of the pool
    * @return uint The number of LP tokens the user staked in the pool
    */
    function balanceOf(address account, address poolAddress) external view returns (uint);

    /**
    * @dev Returns the addresses of pools the user is invested in
    * @return address[] The addresses of pools the user is invested in
    */
    function getUserInvestedPools() external view returns (address[] memory);

    /**
    * @dev Given a pool address, returns the available yield the user has for the pool
    * @param poolAddress Address of the pool
    * @return uint The amount of TGEN yield the user has available for the pool
    */
    function getAvailableYieldForPool(address poolAddress) external view returns (uint);

    /**
    * @dev Stakes the specified amount of LP tokens into the given pool
    * @param poolAddress Address of the pool
    * @param amount The number of LP tokens to stake in the pool
    */
    function stake(address poolAddress, uint amount) external;

    /**
    * @dev Unstakes the specified amount of LP tokens from the given pool
    * @param poolAddress Address of the pool
    * @param amount The number of LP tokens to unstake from the pool
    */
    function unstake(address poolAddress, uint amount) external;

    /**
    * @dev Claims all available yield for the user in the specified pool
    * @param poolAddress Address of the pool
    */
    function claimRewards(address poolAddress) external;

    /**
    * @dev Updates the weekly rewards rate; meant to be called by the contract owner
    * @param newWeeklyRewardsRate The new weekly rewards rate
    */
    function updateWeeklyRewardsRate(uint newWeeklyRewardsRate) external;

    /**
    * @dev Initializes the PoolState for the given pool
    * @param poolAddress Address of the pool
    */
    function initializePool(address poolAddress) external;
}