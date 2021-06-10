pragma solidity >=0.5.0;

//libraries
import './libraries/SafeMath.sol';

import './Pool.sol';
import './AddressResolver.sol';

contract PoolManager is AddressResolver {
    using SafeMath for uint;

    address[] public pools;
    mapping (address => uint[]) public userToPools;
    mapping (address => uint[]) public userToPositions;
    mapping (address => uint) public addressToIndex; // maps to (index + 1); index 0 represents pool not found

    constructor() public {
        _setPoolManagerAddress(address(this));
    }

    /* ========== VIEWS ========== */

    function getUserPools(address user) public view returns(uint[] memory) {
        require(user != address(0), "Invalid address");

        return userToPools[user];
    }

    function getUserPositions(address user) external view returns(uint[] memory) {
        require(user != address(0), "Invalid address");

        return userToPositions[user];
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _addPosition(address user, address poolAddress) internal isValidPoolAddress(poolAddress) {
        userToPositions[user].push(addressToIndex[poolAddress] - 1);
    }

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

    function _createPool(string memory poolName,
                        uint performanceFee,
                        address manager) internal {

        Pool temp = new Pool(poolName,
                            performanceFee,
                            manager);

        address poolAddress = address(temp);
        pools.push(poolAddress);
        userToPools[manager].push(pools.length);
        addressToIndex[poolAddress] = pools.length;
        _addPoolAddress(poolAddress);

        emit CreatedPool(manager, poolAddress, pools.length - 1, block.timestamp);
    }

    /* ========== EVENTS ========== */

    event CreatedPool(address indexed managerAddress, address indexed poolAddress, uint poolIndex, uint timestamp);
}