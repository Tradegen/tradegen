pragma solidity >=0.5.0;

interface ITradegen {

    /**
    * @dev Transfers TGEN internally
    * @param from The address to transfer TGEN from
    * @param to The address to transfer TGEN to
    * @param value The amount of TGEN to transfer
    */
    function restrictedTransfer(address from, address to, uint value) external;

    /**
    * @dev Sends TGEN rewards to the specified user
    * @param to The user to send TGEN rewards to
    * @param value The amount of TGEN rewards to send
    */
    function sendRewards(address to, uint value) external;

    /**
    * @dev Sends TGEN penalty to the specified user; meant to be called when user makes a spurious vote
    * @param to The user to send TGEN penalty to
    * @param value The amount of TGEN penalty to send
    */
    function sendPenalty(address to, uint value) external;
}