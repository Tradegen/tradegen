// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface ITradegenStakingEscrow {

    function claimStakingRewards(address user, uint amount) external;
}