// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface ITradegenEscrow {

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
    * @return A pair of uints: (timestamp, TGEN quantity).
    */
    function getVestingScheduleEntry(address account, uint index) external view returns (uint[2] memory);

    /**
    * @notice Get the time at which a given schedule entry will vest.
    */
    function getVestingTime(address account, uint index) external view returns (uint);

    /**
    * @notice Get the quantity of TGEN associated with a given schedule entry.
    */
    function getVestingQuantity(address account, uint index) external view returns (uint);

    /**
    * @notice Obtain the index of the next schedule entry that will vest for a given user.
    */
    function getNextVestingIndex(address account) external view returns (uint);

    /**
    * @notice Obtain the next schedule entry that will vest for a given user.
    * @return A pair of uints: (timestamp, TGEN quantity). */
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
    * @notice Allow a user to withdraw any TGEN in their schedule that have vested.
    */
    function vest() external;
}