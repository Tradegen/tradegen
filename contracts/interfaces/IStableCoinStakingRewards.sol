pragma solidity >=0.5.0;

interface IStableCoinStakingRewards {

    /**
     * @notice A simple alias to totalVestedAccountBalance: provides ERC20 balance integration.
     */
    function balanceOf(address account) external view returns (uint);

    /**
     * @notice The number of vesting dates in an account's schedule.
     */
    function numVestingEntries(address account) external view returns (uint);

    /**
     * @notice Get a particular schedule entry for an account.
     * @return A pair of uints: (timestamp, cUSD quantity).
     */
    function getVestingScheduleEntry(address account, uint index) external view returns (uint[2] memory);

    /**
     * @notice Get the time at which a given schedule entry will vest.
     */
    function getVestingTime(address account, uint index) external view returns (uint);

    /**
     * @notice Get the quantity of cUSD associated with a given schedule entry.
     */
    function getVestingQuantity(address account, uint index) external view returns (uint);

    /**
     * @notice Obtain the index of the next schedule entry that will vest for a given user.
     */
    function getNextVestingIndex(address account) external view returns (uint);

    /**
     * @notice Obtain the next schedule entry that will vest for a given user.
     * @return A pair of uints: (timestamp, cUSD quantity). */
    function getNextVestingEntry(address account) external view returns (uint[2] memory);

    /**
     * @notice Obtain the time at which the next schedule entry will vest for a given user.
     */
    function getNextVestingTime(address account) external view returns (uint);

    /**
     * @notice Obtain the quantity which the next schedule entry will vest for a given user.
     */
    function getNextVestingQuantity(address account) external view returns (uint);

    /**
     * @notice Allow a user to withdraw any cUSD in their schedule that have vested.
     */
    function vest() external;

    /**
     * @notice Stakes the given cUSD amount.
     */
    function stake(uint amount) external;

    /**
     * @notice Allow a user to claim any available staking rewards.
     */
    function getReward() external;

    /**
     * @notice Calculates the amount of TGEN reward per token staked.
     */
    function rewardPerToken() external view returns (uint256);

    /**
     * @notice Calculates the amount of TGEN rewards earned.
     */
    function earned(address account) external view returns (uint256);

    /**
     * @notice Swaps cUSD for specified asset; meant to be called from LeveragedAssetPositionManager contract
     * @param asset Asset to swap to
     * @param collateral Amount of cUSD to transfer from user
     * @param borrowedAmount Amount of cUSD borrowed
     * @param user Address of the user
     * @return uint Number of asset tokens received
     */
    function swapToAsset(address asset, uint collateral, uint borrowedAmount, address user) external returns (uint);

    /**
     * @notice Swaps specified asset for cUSD; meant to be called from LeveragedAssetPositionManager contract
     * @param asset Asset to swap from
     * @param userShare Amount of cUSD for the user
     * @param poolShare Amount of cUSD for the pool
     * @param numberOfAssetTokens Number of asset tokens to swap
     * @param user Address of the user
     * @return uint Amount of cUSD user received
     */
    function swapFromAsset(address asset, uint userShare, uint poolShare, uint numberOfAssetTokens, address user) external returns (uint);

    /**
     * @notice Liquidates a leveraged asset; meant to be called from LeveragedAssetPositionManager contract
     * @param asset Asset to swap from
     * @param userShare Amount of cUSD for the user
     * @param liquidatorShare Amount of cUSD for the liquidator
     * @param poolShare Amount of cUSD for the pool
     * @param numberOfAssetTokens Number of asset tokens to swap
     * @param user Address of the user
     * @param liquidator Address of the liquidator
     * @return uint Amount of cUSD user received
     */
    function liquidateLeveragedAsset(address asset, uint userShare, uint liquidatorShare, uint poolShare, uint numberOfAssetTokens, address user, address liquidator) external returns (uint);

    /**
     * @notice Pays interest in the given asset; meant to be called from LeveragedAssetPositionManager contract
     * @param asset Asset to swap from
     * @param numberOfAssetTokens Number of asset tokens to swap
     */
    function payInterest(address asset, uint numberOfAssetTokens) external;
}