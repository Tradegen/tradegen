pragma solidity >=0.5.0;

import './Ownable.sol';
import './AddressResolver.sol';
import './TradegenERC20.sol';

import './interfaces/IIndicator.sol';
import './interfaces/IComparator.sol';

contract Components is Ownable, AddressResolver {

    address[] public defaultIndicators;
    address[] public defaultComparators;
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

    function getUserPurchasedIndicators(address user) public view returns (uint[] memory) {
        require(user != address(0), "Invalid user address");

        return userPurchasedIndicators[user];
    }

    function getUserPurchasedComparators(address user) public view returns (uint[] memory) {
        require(user != address(0), "Invalid user address");

        return userPurchasedComparators[user];
    }

    function checkIfUserPurchasedIndicator(address user, uint indicatorIndex) public view returns (bool) {
        require(user != address(0), "Invalid user address");
        require(indicatorIndex >= 0 && indicatorIndex < indicators.length, "Indicator index out of range");

        address indicatorAddress = indicators[indicatorIndex];

        return indicatorUsers[indicatorAddress][user] > 0;
    }

    function checkIfUserPurchasedComparator(address user, uint comparatorIndex) public view returns (bool) {
        require(user != address(0), "Invalid user address");
        require(comparatorIndex >= 0 && comparatorIndex < comparators.length, "Comparators index out of range");

        address comparatorAddress = comparators[comparatorIndex];

        return comparatorUsers[comparatorAddress][user] > 0;
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

    function _addDefaultComponentsToUser(address user) public onlyUserManager(msg.sender) {
        require(user != address(0), "Invalid user address");

        uint[] memory _userPurchasedIndicators = new uint[](defaultIndicators.length);
        uint[] memory _userPurchasedComparators = new uint[](defaultComparators.length);

        for (uint i = 0; i < defaultIndicators.length; i++)
        {
            _userPurchasedIndicators[i] = indicatorAddressToIndex[defaultIndicators[i]] - 1;
            indicatorUsers[defaultIndicators[i]][user] = indicatorAddressToIndex[defaultIndicators[i]];
        }

        for (uint i = 0; i < defaultComparators.length; i++)
        {
            _userPurchasedComparators[i] = comparatorAddressToIndex[defaultComparators[i]] - 1;
            comparatorUsers[defaultComparators[i]][user] = comparatorAddressToIndex[defaultComparators[i]];
        }

        userPurchasedIndicators[user] = _userPurchasedIndicators;
        userPurchasedComparators[user] = _userPurchasedComparators;
    }

    /* ========== EVENTS ========== */

    event AddedIndicator(address indicatorAddress, uint indicatorindex, uint timestamp);
    event AddedComparator(address comparatorAddress, uint comparatorindex, uint timestamp);
}