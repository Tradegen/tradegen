pragma solidity >=0.5.0;

import '../Ownable.sol';

import '../interfaces/IIndicator.sol';

contract NthPriceUpdate is IIndicator, Ownable {

    struct State {
        uint8 N;
        uint128 currentValue;
        uint[] indicatorHistory;
        uint[] priceHistory;
    }

    mapping (address => State) private _tradingBotStates;

    constructor() public Ownable() {}

    function getName() public pure override returns (string memory) {
        return "NthPriceUpdate";
    }

    function addTradingBot(address tradingBotAddress, uint param) public override onlyOwner() {
        require(tradingBotAddress != address(0), "Invalid trading bot address");
        require(_tradingBotStates[tradingBotAddress].currentValue == 0, "Trading bot already exists");
        require(param > 1 && param <= 200, "Param must be between 2 and 200");

        _tradingBotStates[tradingBotAddress] = State(uint8(param), 0, new uint[](0), new uint[](0));
    }

    function update(address tradingBotAddress, uint latestPrice) public override {
        require(tradingBotAddress != address(0), "Invalid trading bot address");

        _tradingBotStates[tradingBotAddress].priceHistory.push(latestPrice);
        _tradingBotStates[tradingBotAddress].indicatorHistory.push((uint256(_tradingBotStates[tradingBotAddress].N) <= _tradingBotStates[tradingBotAddress].priceHistory.length) ? _tradingBotStates[tradingBotAddress].priceHistory[_tradingBotStates[tradingBotAddress].priceHistory.length - uint256(_tradingBotStates[tradingBotAddress].N)] : 0);
    }   

    function getValue(address tradingBotAddress) public view override returns (uint[] memory) {
        require(tradingBotAddress != address(0), "Invalid trading bot address");

        uint[] memory temp = new uint[](1);
        temp[0] = (_tradingBotStates[tradingBotAddress].indicatorHistory.length > 0) ? _tradingBotStates[tradingBotAddress].indicatorHistory[_tradingBotStates[tradingBotAddress].indicatorHistory.length - 1] : 0;
        return temp;
    }

    function getHistory(address tradingBotAddress) public view override returns (uint[] memory) {
        require(tradingBotAddress != address(0), "Invalid trading bot address");

        return _tradingBotStates[tradingBotAddress].indicatorHistory;
    }
}