pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';

contract HighOfLastNPriceUpdates is IIndicator {

    struct State {
        uint currentValue;
        uint N;
        uint[] history;
    }

    mapping (address => State) private _tradingBotStates;

    function getName() public pure override returns (string memory) {
        return "HighOfLastNPriceUpdates";
    }

    function addTradingBot(address tradingBotAddress, uint param) public override {
        require(tradingBotAddress != address(0), "Invalid trading bot address");
        require(_tradingBotStates[tradingBotAddress].currentValue == 0, "Trading bot already exists");
        require(param > 1, "Invalid param");

        _tradingBotStates[tradingBotAddress] = State(0, param, new uint[](0));
    }

    function update(address tradingBotAddress, uint latestPrice) public override {
        require(tradingBotAddress != address(0), "Invalid trading bot address");

        State storage tradingBotState = _tradingBotStates[tradingBotAddress];

        tradingBotState.history.push(latestPrice);

        uint high = 0;

        if (tradingBotState.history.length >= tradingBotState.N)
        {
            for (uint i = 0; i < tradingBotState.N; i++)
            {
                high = (tradingBotState.history[tradingBotState.history.length - i - 1] > high) ? tradingBotState.history[tradingBotState.history.length - i - 1] : high;
            }
        }

        tradingBotState.currentValue = high;
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

        return tradingBotState.history;
    }
}