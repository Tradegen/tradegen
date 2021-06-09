pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';

contract NthPriceUpdate is IIndicator {

    struct State {
        uint8 N;
        uint128 currentValue;
        uint[] indicatorHistory;
        uint[] priceHistory;
    }

    uint public _price;
    address public _developer;

    mapping (address => State) private _tradingBotStates;

    constructor(uint price) public {
        require(price >= 0, "Price must be greater than 0");

        _price = price;
        _developer = msg.sender;
    }

    function getName() public pure override returns (string memory) {
        return "NthPriceUpdate";
    }

    function addTradingBot(uint param) public override {
        require(_tradingBotStates[msg.sender].currentValue == 0, "Trading bot already exists");
        require(param > 1 && param <= 200, "Param must be between 2 and 200");

        _tradingBotStates[msg.sender] = State(uint8(param), 0, new uint[](0), new uint[](0));
    }

    function update(uint latestPrice) public override {
        _tradingBotStates[msg.sender].priceHistory.push(latestPrice);
        _tradingBotStates[msg.sender].indicatorHistory.push((uint256(_tradingBotStates[msg.sender].N) <= _tradingBotStates[msg.sender].priceHistory.length) ? _tradingBotStates[msg.sender].priceHistory[_tradingBotStates[msg.sender].priceHistory.length - uint256(_tradingBotStates[msg.sender].N)] : 0);
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