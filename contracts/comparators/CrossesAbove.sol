pragma solidity >=0.5.0;

import '../AddressResolver.sol';

import '../interfaces/IIndicator.sol';
import '../interfaces/IComparator.sol';

contract CrossesAbove is IComparator {

    struct State {
        address firstIndicatorAddress;
        address secondIndicatorAddress;
        uint firstIndicatorPreviousValue;
        uint secondIndicatorPreviousValue;
    }

    mapping (address => State) private _tradingBotStates;

    function addTradingBot(address tradingBotAddress, address firstIndicatorAddress, address secondIndicatorAddress) public override {
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

        bool result = (tradingBotState.firstIndicatorPreviousValue < tradingBotState.secondIndicatorPreviousValue) &&
                    (firstIndicatorHistory[firstIndicatorHistory.length - 1] > secondIndicatorHistory[secondIndicatorHistory.length - 1]);

        tradingBotState.firstIndicatorPreviousValue = firstIndicatorHistory[firstIndicatorHistory.length - 1];
        tradingBotState.secondIndicatorPreviousValue = secondIndicatorHistory[secondIndicatorHistory.length - 1];

        return result;
    }
}