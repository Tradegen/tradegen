pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';

contract LatestPrice is IIndicator {

    uint public _price;
    address public _developer;

    mapping (address => uint[]) private _tradingBotStates;

    constructor(uint price) public {
        require(price >= 0, "Price must be greater than 0");

        _price = price;
        _developer = msg.sender;
    }

    function getName() public pure override returns (string memory) {
        return "LatestPrice";
    }

    function addTradingBot(uint param) public view override {
        require(_tradingBotStates[msg.sender].length == 0, "Trading bot already exists");
    }

    function update(uint latestPrice) public override {
        _tradingBotStates[msg.sender].push(latestPrice);
    }   

    function getValue(address tradingBotAddress) public view override returns (uint[] memory) {
        require(tradingBotAddress != address(0), "Invalid trading bot address");

        uint[] memory temp = new uint[](1);
        temp[0] = _tradingBotStates[tradingBotAddress][_tradingBotStates[tradingBotAddress].length - 1];

        return temp;
    }

    function getHistory(address tradingBotAddress) public view override returns (uint[] memory) {
        require(tradingBotAddress != address(0), "Invalid trading bot address");

        return _tradingBotStates[tradingBotAddress];
    }
}