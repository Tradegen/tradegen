pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';

contract NthPriceUpdate is IIndicator {

    struct State {
        uint currentValue;
        uint N;
        uint[] indicatorHistory;
        uint[] priceHistory;
    }

    mapping (address => State) private _tradingBotStates;

    function getName() public pure override returns (string memory) {
        return "NthPriceUpdate";
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
        tradingBotState.indicatorHistory.push((tradingBotState.N <= tradingBotState.priceHistory.length) ? tradingBotState.priceHistory[tradingBotState.priceHistory.length - tradingBotState.N] : 0);
    }   

    function getValue(address tradingBotAddress) public view override returns (uint[] memory) {
        require(tradingBotAddress != address(0), "Invalid trading bot address");

        State storage tradingBotState = _tradingBotStates[tradingBotAddress];

        uint[] memory temp = new uint[](1);
        temp[0] = (tradingBotState.indicatorHistory.length > 0) ? tradingBotState.indicatorHistory[tradingBotState.indicatorHistory.length - 1] : 0;
        return temp;
    }

    function getHistory(address tradingBotAddress) public view override returns (uint[] memory) {
        require(tradingBotAddress != address(0), "Invalid trading bot address");

        State storage tradingBotState = _tradingBotStates[tradingBotAddress];

        return tradingBotState.indicatorHistory;
    }
}