// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IStakingFarmRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken(address farm) external view returns (uint256);

    function earned(address account, address farm) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply(address farm) external view returns (uint256);

    function balanceOf(address account, address farm) external view returns (uint256);

    function periodFinish() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    // Mutative

    function stake(uint256 amount, address farm) external;

    function withdraw(uint256 amount, address farm) external;

    function getReward(address farm) external;

    function exit(address farm) external;
}
