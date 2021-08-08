pragma solidity >=0.5.0;

interface ITradegenStakingEscrow {

    function claimStakingRewards(address user, uint amount) external;
}