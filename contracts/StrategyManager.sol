pragma solidity >=0.5.0;

//libraries
import './libraries/SafeMath.sol';

import './Strategy.sol';
import './AddressResolver.sol';

contract StrategyManager is AddressResolver {
    using SafeMath for uint;

    address[] public strategies; // stores contract address of each published strategy
    mapping (address => uint[]) public userToPublishedStrategies; //stores indexes of user's published strategies
    mapping (address => uint[]) public userToPositions; //stores index of user's positions (strategies);
    mapping (address => uint) public addressToIndex; // maps to (index + 1); index 0 represents strategy not found
    mapping (string => uint) public strategySymbolToIndex; //maps to (index + 1); index 0 represents strategy not found
    mapping (string => uint) public strategyNameToIndex; //maps to (index + 1); index 0 represents strategy not found

    constructor() public {
        _setStrategyManagerAddress(address(this));
    }

     /* ========== VIEWS ========== */

    function getUserPublishedStrategies(address user) external view returns(uint[] memory) {
        require(user != address(0), "Invalid address");

        return userToPublishedStrategies[user];
    }

    function getUserPositions(address user) external view returns(uint[] memory) {
        require(user != address(0), "Invalid address");

        return userToPositions[user];
    }

    function getStrategyAddressFromIndex(uint index) external view returns(address) {
        require(index >= 0 && index < strategies.length, "Index out of range");

        return strategies[index];
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _addPosition(address _user, address _strategyAddress) internal isValidStrategyAddress(_strategyAddress) {
        userToPositions[_user].push(addressToIndex[_strategyAddress] - 1);
    }

    function _removePosition(address _user, address _strategyAddress) internal isValidStrategyAddress(_strategyAddress) {
        uint positionIndex;
        uint strategyIndex = addressToIndex[_strategyAddress];

        //bounded by number of strategies
        for (positionIndex = 0; positionIndex < userToPositions[_user].length; positionIndex++)
        {
            if (positionIndex == strategyIndex)
            {
                break;
            }
        }

        require (positionIndex < userToPositions[_user].length, "Position not found");

        userToPositions[_user][positionIndex] = userToPositions[_user][userToPositions[_user].length - 1];
        delete userToPositions[_user][userToPositions[_user].length - 1];
    }

    function _publishStrategy(string memory strategyName,
                            string memory strategySymbol,
                            uint strategyParams,
                            uint[] memory entryRules,
                            uint[] memory exitRules,
                            address developerAddress) internal {

        Strategy temp = new Strategy(strategyName,
                                    strategySymbol,
                                    strategyParams,
                                    entryRules,
                                    exitRules,
                                    developerAddress);

        address strategyAddress = address(temp);
        strategies.push(strategyAddress);
        userToPublishedStrategies[developerAddress].push(strategies.length);
        addressToIndex[strategyAddress] = strategies.length;
        strategySymbolToIndex[strategySymbol] = strategies.length;
        strategyNameToIndex[strategyName] = strategies.length;
        _addStrategyAddress(strategyAddress);

        emit PublishedStrategy(developerAddress, strategyAddress, strategies.length - 1, block.timestamp);
    }

    /* ========== EVENTS ========== */

    event PublishedStrategy(address developerAddress, address strategyAddress, uint strategyIndex, uint timestamp);
}