pragma solidity >=0.5.0;

import './Ownable.sol';
import './AddressResolver.sol';

contract Components is Ownable, AddressResolver {

    address[] public indicators;
    address[] public comparators;

    mapping (address => uint[]) public userPurchasedIndicators;
    mapping (address => uint[]) public userPurchasedComparators;

    mapping (address => mapping (address => uint)) public indicatorUsers; //maps to (index + 1); index 0 represents indicator not purchased by user
    mapping (address => mapping (address => uint)) public comparatorUsers; //maps to (index + 1); index 0 represents comparator not purchased by user

    constructor() public {
        _setComponentsAddress(address(this));
    }

    /* ========== VIEWS ========== */

    function getIndicators() public view returns (address[] memory) {
        return indicators;
    }

    function getComparators() public view returns (address[] memory) {
        return comparators;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function _addNewIndicator(address indicatorAddress) public onlyOwner() {
        require(indicatorAddress != address(0), "Invalid indicator address");

        indicators.push(indicatorAddress);

        emit AddedIndicator(indicatorAddress, indicators.length - 1, block.timestamp);
    }

    function _addNewComparator(address comparatorAddress) public onlyOwner() {
        require(comparatorAddress != address(0), "Invalid comparator address");

        comparators.push(comparatorAddress);

        emit AddedComparator(comparatorAddress, comparators.length - 1, block.timestamp);
    }

    /* ========== EVENTS ========== */

    event AddedIndicator(address indicatorAddress, uint indicatorindex, uint timestamp);
    event AddedComparator(address comparatorAddress, uint comparatorindex, uint timestamp);
}