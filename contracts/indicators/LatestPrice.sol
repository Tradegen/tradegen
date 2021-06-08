pragma solidity >=0.5.0;

import '../Ownable.sol';

import '../interfaces/IIndicator.sol';

contract LatestPrice is IIndicator, Ownable {

    mapping (address => uint[]) private _tradingBotStates;

    constructor() public Ownable() {}

    function getName() public pure override returns (string memory) {
        return "LatestPrice";
    }

    function addTradingBot(address tradingBotAddress, uint param) public override onlyOwner() {
        require(tradingBotAddress != address(0), "Invalid trading bot address");
        require(_tradingBotStates[tradingBotAddress].length == 0, "Trading bot already exists");
    }

    function update(address tradingBotAddress, uint latestPrice) public override {
        require(tradingBotAddress != address(0), "Invalid trading bot address");

        _tradingBotStates[tradingBotAddress].push(latestPrice);
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