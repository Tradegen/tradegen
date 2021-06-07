pragma solidity >=0.5.0;

import '../Ownable.sol';

import '../interfaces/IIndicator.sol';

contract Interval is IIndicator, Ownable {

    mapping (address => uint) private _tradingBotStates;

    constructor() public Ownable() {}

    function getName() public pure override returns (string memory) {
        return "Interval";
    }

    function addTradingBot(address tradingBotAddress, uint param) public override onlyOwner() {
        require(tradingBotAddress != address(0), "Invalid trading bot address");
        require(_tradingBotStates[tradingBotAddress] == 0, "Trading bot already exists");
        require(param > 0, "Invalid param");

        _tradingBotStates[tradingBotAddress] = param;
    }

    function update(address tradingBotAddress, uint latestPrice) public override {}   

    function getValue(address tradingBotAddress) public view override returns (uint[] memory) {
        uint[] memory temp = new uint[](1);
        temp[0] = _tradingBotStates[tradingBotAddress];
        return temp;
    }

    function getHistory(address tradingBotAddress) public view override returns (uint[] memory) {
        uint[] memory temp = new uint[](1);
        temp[0] = _tradingBotStates[tradingBotAddress];
        return temp;
    }
}