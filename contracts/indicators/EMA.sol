pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';
import '../libraries/SafeMath.sol';

contract EMA is IIndicator {
    using SafeMath for uint;

    struct State {
        uint8 EMAperiod;
        uint120 currentValue;
        uint120 previousEMA;
        uint[] indicatorHistory;
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
        return "EMA";
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

    function addTradingBot(uint param) public override {
        require(_tradingBotStates[msg.sender].currentValue == 0, "Trading bot already exists");
        require(param > 1 && param <= 200, "Param must be between 2 and 200");

        _tradingBotStates[msg.sender] = State(uint8(param), 0, 0, new uint[](0));
    }

    function update(uint latestPrice) public override {
        uint currentValue = uint256(_tradingBotStates[msg.sender].currentValue);
        uint multiplier = 2;
        multiplier = multiplier.div(uint256(_tradingBotStates[msg.sender].EMAperiod).add(1));

        _tradingBotStates[msg.sender].currentValue = (currentValue == 0) ? uint120(latestPrice) : uint120((multiplier.mul(latestPrice.sub(uint256(_tradingBotStates[msg.sender].previousEMA)).add(uint256(_tradingBotStates[msg.sender].previousEMA)))));
        _tradingBotStates[msg.sender].previousEMA = uint120(currentValue);

        _tradingBotStates[msg.sender].indicatorHistory.push(uint256(_tradingBotStates[msg.sender].currentValue));
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