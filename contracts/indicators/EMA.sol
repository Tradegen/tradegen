pragma solidity >=0.5.0;

import '../Ownable.sol';

import '../interfaces/IIndicator.sol';
import '../libraries/SafeMath.sol';

contract EMA is IIndicator, Ownable {
    using SafeMath for uint;

    struct State {
        uint8 EMAperiod;
        uint120 currentValue;
        uint120 previousEMA;
        uint[] indicatorHistory;
    }

    mapping (address => State) private _tradingBotStates;

    constructor() public Ownable() {}

    function getName() public pure override returns (string memory) {
        return "EMA";
    }

    function addTradingBot(address tradingBotAddress, uint param) public override onlyOwner() {
        require(tradingBotAddress != address(0), "Invalid trading bot address");
        require(_tradingBotStates[tradingBotAddress].currentValue == 0, "Trading bot already exists");
        require(param > 1 && param <= 200, "Param must be between 2 and 200");

        _tradingBotStates[tradingBotAddress] = State(uint8(param), 0, 0, new uint[](0));
    }

    function update(address tradingBotAddress, uint latestPrice) public override {
        require(tradingBotAddress != address(0), "Invalid trading bot address");

        uint currentValue = uint256(_tradingBotStates[tradingBotAddress].currentValue);
        uint multiplier = 2;
        multiplier = multiplier.div(uint256(_tradingBotStates[tradingBotAddress].EMAperiod).add(1));

        _tradingBotStates[tradingBotAddress].currentValue = (currentValue == 0) ? uint120(latestPrice) : uint120((multiplier.mul(latestPrice.sub(uint256(_tradingBotStates[tradingBotAddress].previousEMA)).add(uint256(_tradingBotStates[tradingBotAddress].previousEMA)))));
        _tradingBotStates[tradingBotAddress].previousEMA = uint120(currentValue);

        _tradingBotStates[tradingBotAddress].indicatorHistory.push(uint256(_tradingBotStates[tradingBotAddress].currentValue));
    }   

    function getValue(address tradingBotAddress) public view override returns (uint[] memory) {
        require(tradingBotAddress != address(0), "Invalid trading bot address");

        uint[] memory temp = new uint[](1);
        temp[0] = uint256(_tradingBotStates[tradingBotAddress].currentValue);
        return temp;
    }

    function getHistory(address tradingBotAddress) public view override returns (uint[] memory) {
        require(tradingBotAddress != address(0), "Invalid trading bot address");

        return _tradingBotStates[tradingBotAddress].indicatorHistory;
    }
}