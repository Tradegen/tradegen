pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';
import '../interfaces/IComparator.sol';

import '../libraries/SafeMath.sol';

contract RisesTo is IComparator {
    using SafeMath for uint;

    struct State {
        address firstIndicatorAddress;
        address secondIndicatorAddress;
        uint firstIndicatorPreviousValue;
        uint secondIndicatorPreviousValue;
    }

    uint public _price;
    address public _developer;

    mapping (address => State) private _tradingBotStates;

    constructor(uint price) public {
        require(price >= 0, "Price must be greater than 0");

        _price = price;
        _developer = msg.sender;
    }

    /**
    * @dev Returns the sale price and the developer of the comparator
    * @return (uint, address) Sale price of the comparator and the comparator's developer
    */
    function getPriceAndDeveloper() public view override returns (uint, address) {
        return (_price, _developer);
    }

    /**
    * @dev Updates the sale price of the comparator; meant to be called by the comparator developer
    * @param newPrice The new sale price of the comparator
    */
    function editPrice(uint newPrice) external override {
        require(msg.sender == _developer, "Only the developer can edit the price");
        require(newPrice >= 0, "Price must be a positive number");

        _price = newPrice;

        emit UpdatedPrice(address(this), newPrice, block.timestamp);
    }

    /**
    * @dev Initializes the state of the trading bot; meant to be called by a trading bot
    * @param firstIndicatorAddress Address of the comparator's first indicator
    * @param secondIndicatorAddress Address of the comparator's second indicator
    */
    function addTradingBot(address firstIndicatorAddress, address secondIndicatorAddress) public override {
        require(firstIndicatorAddress != address(0), "Invalid first indicator address");
        require(secondIndicatorAddress != address(0), "Invalid second indicator address");
        require(_tradingBotStates[msg.sender].firstIndicatorPreviousValue == 0, "Trading bot already exists");

        _tradingBotStates[msg.sender] = State(firstIndicatorAddress, secondIndicatorAddress, 0, 0);
    }

    /**
    * @dev Returns whether the comparator's conditions are met
    * @return bool Whether the comparator's conditions are met after the latest price feed update
    */
    function checkConditions() public override returns (bool) {
        State storage tradingBotState = _tradingBotStates[msg.sender];

        uint[] memory firstIndicatorHistory = IIndicator(tradingBotState.firstIndicatorAddress).getValue(msg.sender);
        uint[] memory secondIndicatorHistory = IIndicator(tradingBotState.secondIndicatorAddress).getValue(msg.sender);

        if (firstIndicatorHistory.length == 0 || secondIndicatorHistory.length == 0)
        {
            return false;
        }

        //first indicator can be within +/- 0.1% of second indicator value and still meet conditions
        uint previousLowerErrorBound = tradingBotState.secondIndicatorPreviousValue.mul(999).div(1000);
        uint currentLowerErrorBound = secondIndicatorHistory[secondIndicatorHistory.length - 1].mul(999).div(1000);
        uint currentUpperErrorBound = secondIndicatorHistory[secondIndicatorHistory.length - 1].mul(1001).div(1000);

        bool result = (tradingBotState.firstIndicatorPreviousValue < previousLowerErrorBound)
                    && (firstIndicatorHistory[firstIndicatorHistory.length - 1] >= currentLowerErrorBound)
                    && (firstIndicatorHistory[firstIndicatorHistory.length - 1] <= currentUpperErrorBound);

        tradingBotState.firstIndicatorPreviousValue = firstIndicatorHistory[firstIndicatorHistory.length - 1];
        tradingBotState.secondIndicatorPreviousValue = secondIndicatorHistory[secondIndicatorHistory.length - 1];

        return result;
    }
}