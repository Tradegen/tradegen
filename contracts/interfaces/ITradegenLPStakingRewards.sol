// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface ITradegenLPStakingRewards {

    /**
     * @notice Returns the current reward per LP token staked.
     */
    function rewardPerToken() external view returns (uint);

    /**
     * @notice Returns the amount of rewards available for the given user.
     * @param account Address of the user.
     */
    function earned(address account) external view returns (uint);

    /**
     * @notice Returns the total number of LP tokens staked.
     */
    function totalSupply() external view returns (uint);

    /**
     * @notice Returns the number of LP tokens staked for the given user.
     * @param account Address of the user.
     */
    function balanceOf(address account) external view returns (uint);

    /**
     * @notice Returns the address of the LP token.
     */
    function stakingToken() external view returns (address);

    /**
     * @notice Returns the address of the reward token.
     */
    function rewardsToken() external view returns (address);

    /**
     * @notice Returns the number of reward tokens distributed per second.
     */
    function rewardRate() external view returns (uint);

    /**
     * @notice Returns the total number of vesting entries for the given user.
     * @param account Address of the user.
     */
    function numVestingEntries(address account) external view returns (uint);

    /**
     * @notice Returns the user's vesting entry at the given index.
     * @dev Returns [0, 0, 0] if the index is out of bounds.
     * @param account Address of the user.
     * @param index Index in the array of vesting entries.
     * @return uint[3] The timestamp, quantity, and number of tokens.
     */
    function getVestingScheduleEntry(address account, uint index) external view returns (uint[3] memory);

    /**
     * @notice Returns the timestamp at which the user's vesting entry will start vesting.
     * @dev Returns 0 if the index is out of bounds.
     * @param account Address of the user.
     * @param index Index in the array of vesting entries.
     * @return uint Timestamp at which vesting starts.
     */
    function getVestingTime(address account, uint index) external view returns (uint);

    /**
     * @notice Returns the number of LP tokens for the user's vesting entry.
     * @dev Returns 0 if the index is out of bounds.
     * @param account Address of the user.
     * @param index Index in the array of vesting entries.
     * @return uint Number of LP tokens.
     */
    function getVestingQuantity(address account, uint index) external view returns (uint);

    /**
     * @notice Returns the adjusted weight for the user's vesting entry.
     * @dev Returns 0 if the index is out of bounds.
     * @param account Address of the user.
     * @param index Index in the array of vesting entries.
     * @return uint Adjusted weight.
     */
    function getVestingTokenAmount(address account, uint index) external view returns (uint);

    /**
     * @notice Returns the index of the user's next vesting entry.
     * @param account Address of the user.
     * @return uint Index of the user's next vesting entry.
     */
    function getNextVestingIndex(address account) external view returns (uint);

    /**
     * @notice Returns the user's next vesting entry.
     * @param account Address of the user.
     * @return uint[3] The timestamp, quantity, and adjusted weight of the next entry.
     */
    function getNextVestingEntry(address account) external view returns (uint[3] memory);

    /**
     * @notice Returns the timestamp of the user's next vesting entry.
     * @param account Address of the user.
     * @return uint Timestamp of the user's next vesting entry.
     */
    function getNextVestingTime(address account) external view returns (uint);

    /**
     * @notice Returns the vesting amount of the user's next vesting entry.
     * @param account Address of the user.
     * @return uint Vesting amount of the user's next vesting entry.
     */
    function getNextVestingQuantity(address account) external view returns (uint);

    /**
     * @notice Stakes LP tokens for the given number of weeks.
     * @dev The number of weeks is capped at 52.
     * @param amount Number of LP tokens to stake.
     * @param numberOfWeeks Number of weeks to stake.
     */
    function stake(uint amount, uint numberOfWeeks) external;

    /**
     * @notice Withdraws any LP tokens that have vested.
     */
    function vest() external;

    /**
     * @notice Claims any available staking rewards.
     */
    function getReward() external;

    /**
     * @notice Calculates the USD value of the given number of LP tokens.
     * @param numberOfTokens Number of LP tokens in the farm.
     * @return uint The USD value of the LP tokens.
     */
    function calculateValueOfLPTokens(uint numberOfTokens) external view returns (uint);

    /**
     * @notice Returns the USD value of all LP tokens staked in this contract.
     */
    function getUSDValueOfContract() external view returns (uint);
}
