pragma solidity >=0.5.0;

interface IPoolRewardsEscrow {

    function claimPoolRewards(address user, uint amount) external;
}