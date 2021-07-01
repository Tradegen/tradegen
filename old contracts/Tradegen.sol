pragma solidity >=0.5.0;

//Inheritance
import './interfaces/ITradegen.sol';
import './TradegenERC20.sol';

contract Tradegen is ITradegen, TradegenERC20 {

    address private _componentsAddress;
    address private _stakingRewardsAddress;

    constructor(address componentsAddress, address stakingRewardsAddress) public {
        _componentsAddress = componentsAddress;
        _stakingRewardsAddress = stakingRewardsAddress;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @dev Transfers TGEN internally
    * @param from The address to transfer TGEN from
    * @param to The address to transfer TGEN to
    * @param value The amount of TGEN to transfer
    */
    function restrictedTransfer(address from, address to, uint value) public override isValidAddress(msg.sender) {
        _transfer(from, to, value);
    }

    /**
    * @dev Sends TGEN rewards to the specified user
    * @param to The user to send TGEN rewards to
    * @param value The amount of TGEN rewards to send
    */
    function sendRewards(address to, uint value) public override isValidAddress(msg.sender) {
        _mint(to, value);
    }

    /**
    * @dev Sends TGEN penalty to the specified user; meant to be called when user makes a spurious vote
    * @param from The user to send TGEN penalty to
    * @param value The amount of TGEN penalty to send
    */
    function sendPenalty(address from, uint value) public override isValidAddress(msg.sender) {
        _burn(from, value);
    }

    /* ========== MODIFIERS ========== */

    modifier isValidAddress(address addressToCheck) {
        require(addressToCheck == _componentsAddress || addressToCheck == _stakingRewardsAddress, "Address is not permitted");
        _;
    }
}