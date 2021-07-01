pragma solidity >=0.5.0;

//Interfaces
import './interfaces/IPool.sol';
import './interfaces/ISettings.sol';

import './PoolManager.sol';

contract PoolProxy is PoolManager {
    using SafeMath for uint;

    ISettings public immutable SETTINGS;

    constructor(ISettings settings, IUserPoolFarm farm, IAddressResolver addressResolver) PoolManager(farm, addressResolver) public {
        SETTINGS = settings;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @dev Creates a new pool
    * @param poolName Name of the pool
    * @param performanceFee Performance fee for the pool
    */
    function createPool(string memory poolName, uint performanceFee) external {
        require(bytes(poolName).length < 30, "Pool name must have less than 30 characters");
        require(performanceFee <= SETTINGS.getParameterValue("MaximumPerformanceFee"), "Cannot exceed maximum performance fee");
        require(getUserPools(msg.sender).length < SETTINGS.getParameterValue("MaximumNumberOfPoolsPerUser"), "Cannot exceed maximum number of pools per user");

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