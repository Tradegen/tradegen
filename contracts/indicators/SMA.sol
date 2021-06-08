pragma solidity >=0.5.0;

import '../Ownable.sol';

import '../interfaces/IIndicator.sol';
import '../libraries/SafeMath.sol';

contract SMA is IIndicator, Ownable {
    using SafeMath for uint;

    struct State {
        uint SMAperiod;
        uint currentValue;
        uint total;
        uint[] priceHistory;
        uint[] indicatorHistory;
    }

    mapping (address => State) private _tradingBotStates;

    constructor() public Ownable() {}

    function getName() public pure override returns (string memory) {
        return "SMA";
    }

    function addTradingBot(address tradingBotAddress, uint param) public override onlyOwner() {
        require(tradingBotAddress != address(0), "Invalid trading bot address");
        require(_tradingBotStates[tradingBotAddress].currentValue == 0, "Trading bot already exists");
        require(param > 1 && param <= 200, "Param must be between 2 and 200");

        _tradingBotStates[tradingBotAddress] = State(0, param, 0, new uint[](0), new uint[](0));
    }

    function update(address tradingBotAddress, uint latestPrice) public override {
        require(tradingBotAddress != address(0), "Invalid trading bot address");

        State storage tradingBotState = _tradingBotStates[tradingBotAddress];

        tradingBotState.priceHistory.push(latestPrice);
        tradingBotState.total = tradingBotState.total.add(latestPrice);

        if (tradingBotState.priceHistory.length >= tradingBotState.SMAperiod)
        {
            if (tradingBotState.priceHistory.length > tradingBotState.SMAperiod)
            {
                tradingBotState.total = tradingBotState.total.sub(tradingBotState.priceHistory[tradingBotState.priceHistory.length - tradingBotState.SMAperiod]);
            }

            tradingBotState.currentValue = tradingBotState.total.div(tradingBotState.SMAperiod);
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