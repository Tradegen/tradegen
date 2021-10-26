// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface ITradegenLPStakingRewards {

    function rewardPerToken() external view returns (uint);

    function earned(address account) external view returns (uint);

    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function stakingToken() external view returns (address);

    function rewardsToken() external view returns (address);

    function rewardRate() external view returns (uint);

    function numVestingEntries(address account) external view returns (uint);

    function getVestingScheduleEntry(address account, uint index) external view returns (uint[3] memory);

    function getVestingTime(address account, uint index) external view returns (uint);

    function getVestingQuantity(address account, uint index) external view returns (uint);

    function getVestingTokenAmount(address account, uint index) external view returns (uint);

    function getNextVestingIndex(address account) external view returns (uint);

    function getNextVestingEntry(address account) external view returns (uint[3] memory);

    function getNextVestingTime(address account) external view returns (uint);

    function getNextVestingQuantity(address account) external view returns (uint);

    function stake(uint amount, uint numberOfWeeks) external;

    function vest() external;

    function getReward() external;

    function calculateValueOfLPTokens(uint numberOfTokens) external view returns (uint);

    /**
     * @notice Returns the USD value of all LP tokens staked in this contract
     * @return uint USD value of this contract
     */
    function getUSDValueOfContract() external view returns (uint);
}
