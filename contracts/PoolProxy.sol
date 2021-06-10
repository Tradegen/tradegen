pragma solidity >=0.5.0;

import './libraries/SafeMath.sol';

import './interfaces/IPool.sol';

import './PoolManager.sol';
import './Settings.sol';

contract PoolProxy is PoolManager {
    using SafeMath for uint;

    constructor() public {
        _setPoolProxyAddress(address(this));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createPool(string memory poolName, uint performanceFee) external {
        require(bytes(poolName).length < 30, "Pool name must have less than 30 characters");
        require(performanceFee <= Settings(getSettingsAddress()).getMaximumPerformanceFee(), "Cannot exceed maximum performance fee");
        require(getUserPools(msg.sender).length < Settings(getSettingsAddress()).getMaximumNumberOfPoolsPerUser(), "Cannot exceed maximum number of pools per user");

        _createPool(poolName, performanceFee, msg.sender);
    }

    function withdraw(address poolAddress, uint amount) external isValidPoolAddress(poolAddress) {
        require(amount > 0, "Withdrawal amount must be greater than 0");

        IPool(poolAddress).withdraw(msg.sender, amount);
    }
}