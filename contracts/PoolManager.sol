pragma solidity >=0.5.0;

//Interfaces
import './interfaces/IAddressResolver.sol';
import './interfaces/IPool.sol';
import './interfaces/IStakingRewards.sol';

//Libraries
import './libraries/SafeMath.sol';

//Internal references
import './Pool.sol';

contract PoolManager {
    using SafeMath for uint;

    IAddressResolver public immutable ADDRESS_RESOLVER;

    address[] public pools;
    mapping (address => uint[]) public userToManagedPools;
    mapping (address => uint[]) public userToInvestedPools;
    mapping (address => uint) public addressToIndex; // maps to (index + 1); index 0 represents pool not found

    constructor(IAddressResolver addressResolver) public {
        ADDRESS_RESOLVER = addressResolver;
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Returns the address of each available pool
    * @return address[] The address of each available pool
    */
    function _getAvailablePools() internal view returns(address[] memory) {
        return pools;
    }

    /**
    * @dev Returns the address of each pool the user manages
    * @param user Address of the user
    * @return address[] The address of each pool the user manages
    */
    function _getUserManagedPools(address user) internal view returns(address[] memory) {
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
    * @dev Returns the address of each pool the user is invested in
    * @param user Address of the user
    * @return address[] The address of each pool the user is invested in
    */
    function _getUserInvestedPools(address user) internal view returns(address[] memory) {
        require(user != address(0), "Invalid address");

        address[] memory addresses = new address[](userToInvestedPools[user].length);
        uint[] memory indexes = userToInvestedPools[user];

        for (uint i = 0; i < addresses.length; i++)
        {
            uint index = indexes[i];
            addresses[i] = pools[index];
        }

        return addresses;
    }

    /**
    * @dev Returns the address of each pool the user is staked in
    * @param user Address of the user
    * @return address[] The address of each pool the user is staked in
    * @return uint Number of pools the user is staked in
    */
    function _getUserStakedPools(address user) internal view returns(address[] memory, uint) {
        require(user != address(0), "Invalid address");

        uint numberOfStakedPools = 0;
        address[] memory stakedPools = new address[](userToInvestedPools[user].length);
        uint[] memory investedPools = userToInvestedPools[user];

        for (uint i = 0; i < stakedPools.length; i++)
        {
            uint index = investedPools[i];
            address poolAddress = pools[index];
            address farmAddress = IPool(poolAddress).getFarmAddress();
            uint stakedBalance = (farmAddress != address(0)) ? IStakingRewards(farmAddress).balanceOf(user) : 0;

            if (stakedBalance > 0)
            {
                stakedPools[numberOfStakedPools] = poolAddress;
                numberOfStakedPools++;
            }
        }

        return (stakedPools, numberOfStakedPools);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @dev Adds the index of the given pool to the user's array of invested pools
    * @param user Address of the user
    * @param poolAddress Address of the pool
    */
    function _addPosition(address user, address poolAddress) internal isValidPoolAddress(poolAddress) {
        userToInvestedPools[user].push(addressToIndex[poolAddress] - 1);
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
        for (positionIndex = 0; positionIndex < userToInvestedPools[user].length; positionIndex++)
        {
            if (positionIndex == poolIndex)
            {
                break;
            }
        }

        require (positionIndex < userToInvestedPools[user].length, "Position not found");

        userToInvestedPools[user][positionIndex] = userToInvestedPools[user][userToInvestedPools[user].length - 1];
        delete userToInvestedPools[user][userToInvestedPools[user].length - 1];
    }

    /**
    * @dev Creates a new pool
    * @param poolName Name of the pool
    * @param performanceFee Performance fee of the pool
    * @param manager User who manages the pool
    */
    function _createPool(string memory poolName, uint performanceFee, address manager) internal returns(address) {
        Pool temp = new Pool(poolName, performanceFee, manager, ADDRESS_RESOLVER);

        address poolAddress = address(temp);
        pools.push(poolAddress);
        userToManagedPools[manager].push(pools.length - 1);
        addressToIndex[poolAddress] = pools.length;

        emit CreatedPool(manager, poolAddress, pools.length - 1, block.timestamp);

        return poolAddress;
    }

    /**
    * @dev Deposit cUSD into the given pool
    * @param user Address of the user
    * @param poolAddress Address of the pool
    */
    function _deposit(address user, address poolAddress) internal {
        if (IPool(poolAddress).balanceOf(user) == 0)
        {
            uint index = addressToIndex[poolAddress] - 1;
            userToInvestedPools[user].push(index);
        } 
    }

    /**
    * @dev Withdraw cUSD from the given pool
    * @param user Address of the user
    * @param poolAddress Address of the pool
    */
    function _withdraw(address user, address poolAddress) internal {
        if (IPool(poolAddress).balanceOf(user) == 0)
        {
            _removePosition(user, poolAddress);
        }
    }

    /* ========== MODIFIERS ========== */

    modifier isValidPoolAddress(address poolAddress) {
        require(ADDRESS_RESOLVER.checkIfPoolAddressIsValid(poolAddress), "Invalid pool address");
        _;
    }

    modifier onlyManager(address poolAddress) {
        address managerAddress = IPool(poolAddress).getManagerAddress();

        require(msg.sender == managerAddress, "Only the pool's manager can call this function");
        _;
    }

    /* ========== EVENTS ========== */

    event CreatedPool(address indexed managerAddress, address indexed poolAddress, uint poolIndex, uint timestamp);
}