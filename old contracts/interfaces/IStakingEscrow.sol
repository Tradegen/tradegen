pragma solidity >=0.5.0;

interface IStakingEscrow {

    function claimStakingRewards(address user, uint amount) external;
}