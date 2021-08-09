pragma solidity >=0.5.0;

interface IStakingFarmRewards {

    /**
     * @notice A simple alias to totalVestedAccountBalance: provides ERC20 balance integration.
     */
    function balanceOf(address account, address farmAddress) external view returns (uint);

    /**
     * @notice The number of vesting dates in an account's schedule for the given farm.
     */
    function numVestingEntries(address account, address farmAddress) external view returns (uint);

    /**
     * @notice Get a particular schedule entry for an account for the given farm.
     * @return A pair of uints: (timestamp, LP token quantity).
     */
    function getVestingScheduleEntry(address account, uint index, address farmAddress) external view returns (uint[2] memory);

    /**
     * @notice Get the time at which a given schedule entry will vest.
     */
    function getVestingTime(address account, uint index, address farmAddress) external view returns (uint);

    /**
     * @notice Get the quantity of LP tokens associated with a given schedule entry for the given farm.
     */
    function getVestingQuantity(address account, uint index, address farmAddress) external view returns (uint);

    /**
     * @notice Obtain the index of the next schedule entry that will vest for a given user.
     */
    function getNextVestingIndex(address account, address farmAddress) external view returns (uint);

    /**
     * @notice Obtain the next schedule entry that will vest for a given user.
     * @return A pair of uints: (timestamp, LP token quantity). */
    function getNextVestingEntry(address account, address farmAddress) external view returns (uint[2] memory);

    /**
     * @notice Obtain the time at which the next schedule entry will vest for a given user.
     */
    function getNextVestingTime(address account, address farmAddress) external view returns (uint);

    /**
     * @notice Obtain the quantity which the next schedule entry will vest for a given user.
     */
    function getNextVestingQuantity(address account, address farmAddress) external view returns (uint);

    /**
     * @notice Allow a user to withdraw any LP tokens in their schedule that have vested.
     */
    function vest(address farmAddress) external;

    /**
     * @notice Stakes the given LP token amount.
     */
    function stake(uint amount, address farmAddress) external;

    /**
     * @notice Allow a user to claim any available staking rewards for the given farm.
     */
    function getReward(address farmAddress) external;

    /**
     * @notice Calculates the amount of TGEN reward per token staked in the given farm.
     */
    function rewardPerToken(address farmAddress) external view returns (uint256);

    /**
     * @notice Calculates the amount of TGEN rewards earned for the given farm.
     */
    function earned(address account, address farmAddress) external view returns (uint256);

    /**
     * @notice Returns the user's staked farms, balance in each staked farm, and the number of staked farms
     * @param account Address of the user
     * @return (address[], uint[], uint) The address of each staked farm, user's balance in the associated farm, and the number of staked farms
     */
    function getStakedFarms(address account) external view returns (address[] memory, uint[] memory, uint);

    /**
     * @notice Returns the USD value of the user's staked position in the given farm
     * @param account Address of the user
     * @param farmAddress Address of the farm
     * @return uint USD value of the staked position
     */
    function getUSDValueOfStakedPosition(address account, address farmAddress) external view returns (uint);

    /**
     * @notice Returns the USD value of the given farm
     * @param farmAddress Address of the farm
     * @return uint USD value staked in the farm
     */
    function getUSDValueOfFarm(address farmAddress) external view returns (uint);
}