pragma solidity >=0.5.0;

import '../Ownable.sol';

import '../interfaces/IIndicator.sol';
import '../interfaces/IComparator.sol';

import '../libraries/SafeMath.sol';

contract FallsTo is IComparator, Ownable {
    using SafeMath for uint;

    struct State {
        address firstIndicatorAddress;
        address secondIndicatorAddress;
        uint firstIndicatorPreviousValue;
        uint secondIndicatorPreviousValue;
    }

    mapping (address => State) private _tradingBotStates;

    constructor() public Ownable() {}

    function addTradingBot(address tradingBotAddress, address firstIndicatorAddress, address secondIndicatorAddress) public override onlyOwner() {
        require(tradingBotAddress != address(0), "Invalid trading bot address");
        require(firstIndicatorAddress != address(0), "Invalid first indicator address");
        require(secondIndicatorAddress != address(0), "Invalid second indicator address");
        require(_tradingBotStates[tradingBotAddress].firstIndicatorPreviousValue == 0, "Trading bot already exists");

        _tradingBotStates[tradingBotAddress] = State(firstIndicatorAddress, secondIndicatorAddress, 0, 0);
    }

    function checkConditions(address tradingBotAddress) public override returns (bool) {
        require(tradingBotAddress != address(0), "Invalid trading bot address");

        State storage tradingBotState = _tradingBotStates[tradingBotAddress];

        uint[] memory firstIndicatorHistory = IIndicator(tradingBotState.firstIndicatorAddress).getValue(tradingBotAddress);
        uint[] memory secondIndicatorHistory = IIndicator(tradingBotState.secondIndicatorAddress).getValue(tradingBotAddress);

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