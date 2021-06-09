pragma solidity >=0.5.0;

import './Ownable.sol';
import './AddressResolver.sol';
import './TradegenERC20.sol';

import './interfaces/IIndicator.sol';
import './interfaces/IComparator.sol';

contract Components is Ownable, AddressResolver {

    address[] public indicators;
    address[] public comparators;

    mapping (address => uint) public indicatorAddressToIndex; //maps to (index + 1); index 0 represents indicator address not valid
    mapping (address => uint) public comparatorAddressToIndex; //maps to (index + 1); index 0 represents comparator address not valid

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

    /* ========== MUTATIVE FUNCTIONS ========== */

    function buyIndicator(address indicatorAddress) public {
        require(indicatorAddress != address(0), "Invalid indicator address");
        require(indicatorAddressToIndex[indicatorAddress] > 0, "Invalid indicator address");
        require(indicatorUsers[indicatorAddress][msg.sender] > 0, "Already purchased this indicator");

        (uint price, address developer) = IIndicator(indicatorAddress).getPriceAndDeveloper();

        TradegenERC20(getBaseTradegenAddress()).restrictedTransfer(msg.sender, developer, price);

        indicatorUsers[indicatorAddress][msg.sender] = indicatorAddressToIndex[indicatorAddress];
        userPurchasedIndicators[msg.sender].push(indicatorAddressToIndex[indicatorAddress] - 1);
    }

    function buyComparator(address comparatorAddress) public {
        require(comparatorAddress != address(0), "Invalid comparator address");
        require(comparatorAddressToIndex[comparatorAddress] > 0, "Invalid comparator address");
        require(comparatorUsers[comparatorAddress][msg.sender] > 0, "Already purchased this comparator");

        (uint price, address developer) = IComparator(comparatorAddress).getPriceAndDeveloper();

        TradegenERC20(getBaseTradegenAddress()).restrictedTransfer(msg.sender, developer, price);

        comparatorUsers[comparatorAddress][msg.sender] = comparatorAddressToIndex[comparatorAddress];
        userPurchasedComparators[msg.sender].push(comparatorAddressToIndex[comparatorAddress] - 1);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function _addNewIndicator(address indicatorAddress) public onlyOwner() {
        require(indicatorAddress != address(0), "Invalid indicator address");

        indicators.push(indicatorAddress);
        indicatorAddressToIndex[indicatorAddress] = indicators.length;

        emit AddedIndicator(indicatorAddress, indicators.length - 1, block.timestamp);
    }

    function _addNewComparator(address comparatorAddress) public onlyOwner() {
        require(comparatorAddress != address(0), "Invalid comparator address");

        comparators.push(comparatorAddress);
        comparatorAddressToIndex[comparatorAddress] = comparators.length;

        emit AddedComparator(comparatorAddress, comparators.length - 1, block.timestamp);
    }

    /* ========== EVENTS ========== */

    event AddedIndicator(address indicatorAddress, uint indicatorindex, uint timestamp);
    event AddedComparator(address comparatorAddress, uint comparatorindex, uint timestamp);
}