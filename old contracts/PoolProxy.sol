pragma solidity >=0.5.0;

//Interfaces
import './interfaces/IPool.sol';
import './interfaces/ISettings.sol';
import './interfaces/IAddressResolver.sol';

import './PoolManager.sol';

contract PoolProxy is PoolManager {
    using SafeMath for uint;

    constructor(IAddressResolver addressResolver) PoolManager(addressResolver) public {
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @dev Creates a new pool
    * @param poolName Name of the pool
    * @param performanceFee Performance fee for the pool
    */
    function createPool(string memory poolName, uint performanceFee) external {
        address settingsAddress = ADDRESS_RESOLVER.getContractAddress("Settings");
        uint maximumPerformanceFee = ISettings(settingsAddress).getParameterValue("MaximumPerformanceFee");
        uint maximumNumberOfPoolsPerUser = ISettings(settingsAddress).getParameterValue("MaximumNumberOfPoolsPerUser");

        require(bytes(poolName).length < 30, "Pool name must have less than 30 characters");
        require(performanceFee <= maximumPerformanceFee, "Cannot exceed maximum performance fee");
        require(getUserPools(msg.sender).length < maximumNumberOfPoolsPerUser, "Cannot exceed maximum number of pools per user");

        _createPool(poolName, performanceFee, msg.sender);
    }

    /**
    * @dev Withdraw cUSD from the given pool
    * @param poolAddress Address of the pool
    * @param amount Amount of cUSD to withdraw from the pool
    */
    function withdraw(address poolAddress, uint amount) external isValidPoolAddress(poolAddress) {
        require(amount > 0, "Withdrawal amount must be greater than 0");

        IPool(poolAddress).withdraw(msg.sender, amount);
    }
}