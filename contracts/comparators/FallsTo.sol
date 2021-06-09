pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';
import '../interfaces/IComparator.sol';

import '../libraries/SafeMath.sol';

contract FallsTo is IComparator {
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

    function getPriceAndDeveloper() public view override returns (uint, address) {
        return (_price, _developer);
    }

    function editPrice(uint newPrice) external override {
        require(msg.sender == _developer, "Only the developer can edit the price");
        require(newPrice >= 0, "Price must be a positive number");

        _price = newPrice;

        emit UpdatedPrice(address(this), newPrice, block.timestamp);
    }

    function addTradingBot(address firstIndicatorAddress, address secondIndicatorAddress) public override {
        require(firstIndicatorAddress != address(0), "Invalid first indicator address");
        require(secondIndicatorAddress != address(0), "Invalid second indicator address");
        require(_tradingBotStates[msg.sender].firstIndicatorPreviousValue == 0, "Trading bot already exists");

        _tradingBotStates[msg.sender] = State(firstIndicatorAddress, secondIndicatorAddress, 0, 0);
    }

    function checkConditions() public override returns (bool) {
        State storage tradingBotState = _tradingBotStates[msg.sender];

        uint[] memory firstIndicatorHistory = IIndicator(tradingBotState.firstIndicatorAddress).getValue(msg.sender);
        uint[] memory secondIndicatorHistory = IIndicator(tradingBotState.secondIndicatorAddress).getValue(msg.sender);

        if (firstIndicatorHistory.length == 0 || secondIndicatorHistory.length == 0)
        {
            return false;
        }

        uint previousUpperErrorBound = tradingBotState.secondIndicatorPreviousValue.mul(1001).div(1000);
        uint currentLowerErrorBound = secondIndicatorHistory[secondIndicatorHistory.length - 1].mul(999).div(1000);
        uint currentUpperErrorBound = secondIndicatorHistory[secondIndicatorHistory.length - 1].mul(1001).div(1000);

        bool result = (tradingBotState.firstIndicatorPreviousValue > previousUpperErrorBound)
                    && (firstIndicatorHistory[firstIndicatorHistory.length - 1] >= currentLowerErrorBound)
                    && (firstIndicatorHistory[firstIndicatorHistory.length - 1] <= currentUpperErrorBound);

        tradingBotState.firstIndicatorPreviousValue = firstIndicatorHistory[firstIndicatorHistory.length - 1];
        tradingBotState.secondIndicatorPreviousValue = secondIndicatorHistory[secondIndicatorHistory.length - 1];

        return result;
    }
}