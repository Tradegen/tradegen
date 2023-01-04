// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface ITradegenStakingEscrow {
    /**
    * @notice Withdraws the given amount of tokens from escrow and transfer them to the given user.
    * @dev Transaction will revert if the given amount exceeds the user's balance.
    * @param user Address of the user.
    * @param amount Amount of tokens to withdraw.
    */
    function claimStakingRewards(address user, uint amount) external;
}