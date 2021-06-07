pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';
import '../libraries/SafeMath.sol';

contract EMA is IIndicator {
    using SafeMath for uint;

    struct State {
        uint currentValue;
        uint EMAperiod;
        uint[] priceHistory;
        uint[] indicatorHistory;
    }

    mapping (address => State) private _tradingBotStates;

    function getName() public pure override returns (string memory) {
        return "EMA";
    }

    function addTradingBot(address tradingBotAddress, uint param) public override {
        require(tradingBotAddress != address(0), "Invalid trading bot address");
        require(_tradingBotStates[tradingBotAddress].currentValue == 0, "Trading bot already exists");
        require(param > 1, "Invalid param");

        _tradingBotStates[tradingBotAddress] = State(0, param, new uint[](0), new uint[](0));
    }

    function update(address tradingBotAddress, uint latestPrice) public override {
        require(tradingBotAddress != address(0), "Invalid trading bot address");

        State storage tradingBotState = _tradingBotStates[tradingBotAddress];

        tradingBotState.priceHistory.push(latestPrice);

        if (tradingBotState.priceHistory.length >= tradingBotState.EMAperiod)
        {
            uint temp = 0;
            uint initialEMA = 0;
            uint multiplier = 2;
            multiplier = multiplier.div(tradingBotState.EMAperiod.add(1));

            for (uint i = tradingBotState.EMAperiod; i >= 1; i--)
            {
                if (i == tradingBotState.EMAperiod)
                {
                    initialEMA = tradingBotState.priceHistory[tradingBotState.priceHistory.length - i];
                    temp = initialEMA;
                }
                else
                {
                    temp = multiplier.mul(tradingBotState.priceHistory[tradingBotState.priceHistory.length - i]).add((1 - multiplier).mul(initialEMA));
                    initialEMA = temp;
                }
            }

            tradingBotState.currentValue = temp;
        }

        tradingBotState.indicatorHistory.push(tradingBotState.currentValue);
    }   

    function getValue(address tradingBotAddress) public view override returns (uint[] memory) {
        require(tradingBotAddress != address(0), "Invalid trading bot address");

        State storage tradingBotState = _tradingBotStates[tradingBotAddress];

        uint[] memory temp = new uint[](1);
        temp[0] = tradingBotState.currentValue;
        return temp;
    }

    function getHistory(address tradingBotAddress) public view override returns (uint[] memory) {
        require(tradingBotAddress != address(0), "Invalid trading bot address");

        State storage tradingBotState = _tradingBotStates[tradingBotAddress];

        return tradingBotState.indicatorHistory;
    }
}