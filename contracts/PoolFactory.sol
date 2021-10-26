// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//Interfaces
import './interfaces/ISettings.sol';
import './interfaces/IAddressResolver.sol';

//Inheritance
import './Ownable.sol';

//Internal references
import './Pool.sol';

contract PoolFactory is Ownable {
    using SafeMath for uint;

    IAddressResolver public immutable ADDRESS_RESOLVER;

    address[] public pools;
    mapping (address => uint[]) public userToManagedPools;
    mapping (address => uint) public addressToIndex; // maps to (index + 1); index 0 represents pool not found

    constructor(IAddressResolver addressResolver) Ownable() {
        ADDRESS_RESOLVER = addressResolver;
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Returns the address of each pool the user manages
    * @param user Address of the user
    * @return address[] The address of each pool the user manages
    */
    function getUserManagedPools(address user) external view returns(address[] memory) {
        require(user != address(0), "Invalid address");

        address[] memory addresses = new address[](userToManagedPools[user].length);
        uint[] memory indexes = userToManagedPools[user];

        for (uint i = 0; i < addresses.length; i++)
        {
            uint index = indexes[i];
            addresses[i] = pools[index];
        }

        return addresses;
    }

    /**
    * @dev Returns the address of each available pool
    * @return address[] The address of each available pool
    */
    function getAvailablePools() external view returns(address[] memory) {
        return pools;
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
        require(userToManagedPools[msg.sender].length < maximumNumberOfPoolsPerUser, "Cannot exceed maximum number of pools per user");

        //Create pool
        Pool temp = new Pool(poolName, performanceFee, msg.sender, ADDRESS_RESOLVER);

        //Update state variables
        address poolAddress = address(temp);
        pools.push(poolAddress);
        userToManagedPools[msg.sender].push(pools.length - 1);
        addressToIndex[poolAddress] = pools.length;
        ADDRESS_RESOLVER.addPoolAddress(poolAddress);

        emit CreatedPool(msg.sender, poolAddress, pools.length - 1, block.timestamp);
    }

    /* ========== MODIFIERS ========== */

    modifier isValidPoolAddress(address poolAddress) {
        require(poolAddress != address(0), "PoolFactory: Invalid pool address");
        require(addressToIndex[poolAddress] > 0, "PoolFactory: Pool not found");
        _;
    }

    /* ========== EVENTS ========== */

    event CreatedPool(address indexed managerAddress, address indexed poolAddress, uint poolIndex, uint timestamp);
}