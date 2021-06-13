pragma solidity >=0.5.0;

//Interfaces
import './interfaces/IUserPoolFarm.sol';
import './interfaces/IAddressResolver.sol';

//Libraries
import './libraries/SafeMath.sol';

import './Pool.sol';

contract PoolManager {
    using SafeMath for uint;

    IUserPoolFarm public immutable FARM;
    IAddressResolver public immutable ADDRESS_RESOLVER;

    address[] public pools;
    mapping (address => uint[]) public userToPools;
    mapping (address => uint[]) public userToPositions;
    mapping (address => uint) public addressToIndex; // maps to (index + 1); index 0 represents pool not found

    constructor(IUserPoolFarm userPoolFarm, IAddressResolver addressResolver) public {
        FARM = userPoolFarm;
        ADDRESS_RESOLVER = addressResolver;
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Returns the index of each pool the user manages
    * @param user Address of the user
    * @return uint[] The index in pools array of each pool the user manages
    */
    function getUserPools(address user) public view returns(uint[] memory) {
        require(user != address(0), "Invalid address");

        return userToPools[user];
    }

    /**
    * @dev Returns the index of each pool the user is invested in
    * @param user Address of the user
    * @return uint[] The index in pools array of each pool the user is invested in
    */
    function getUserPositions(address user) external view returns(uint[] memory) {
        require(user != address(0), "Invalid address");

        return userToPositions[user];
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
    * @dev Adds the index of the given pool to the user's array of invested pools
    * @param user Address of the user
    * @param poolAddress Address of the pool
    */
    function _addPosition(address user, address poolAddress) internal isValidPoolAddress(poolAddress) {
        userToPositions[user].push(addressToIndex[poolAddress] - 1);
    }

    /**
    * @dev Removes the index of the given pool from the user's array of invested pools
    * @param user Address of the user
    * @param poolAddress Address of the pool
    */
    function _removePosition(address user, address poolAddress) internal isValidPoolAddress(poolAddress) {
        uint positionIndex;
        uint poolIndex = addressToIndex[poolAddress];

        //bounded by number of strategies
        for (positionIndex = 0; positionIndex < userToPositions[user].length; positionIndex++)
        {
            if (positionIndex == poolIndex)
            {
                break;
            }
        }

        require (positionIndex < userToPositions[user].length, "Position not found");

        userToPositions[user][positionIndex] = userToPositions[user][userToPositions[user].length - 1];
        delete userToPositions[user][userToPositions[user].length - 1];
    }

    /**
    * @dev Creates a new pool
    * @param poolName Name of the pool
    * @param performanceFee Performance fee of the pool
    * @param manager User who manages the pool
    */
    function _createPool(string memory poolName, uint performanceFee, address manager) internal {

        Pool temp = new Pool(poolName, performanceFee, manager, ADDRESS_RESOLVER);

        address poolAddress = address(temp);
        pools.push(poolAddress);
        userToPools[manager].push(pools.length);
        addressToIndex[poolAddress] = pools.length;
        ADDRESS_RESOLVER.addPoolAddress(poolAddress);
        FARM.initializePool(poolAddress);

        emit CreatedPool(manager, poolAddress, pools.length - 1, block.timestamp);
    }

    /* ========== MODIFIERS ========== */

    modifier isValidPoolAddress(address poolAddress) {
        require(ADDRESS_RESOLVER.checkIfPoolAddressIsValid(poolAddress), "Invalid pool address");
        _;
    }

    /* ========== EVENTS ========== */

    event CreatedPool(address indexed managerAddress, address indexed poolAddress, uint poolIndex, uint timestamp);
}