pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';

contract Interval is IIndicator {

    uint public _price;
    address public _developer;

    mapping (address => uint) private _tradingBotStates;

    constructor(uint price) public {
        require(price >= 0, "Price must be greater than 0");

        _price = price;
        _developer = msg.sender;
    }

    function getName() public pure override returns (string memory) {
        return "Interval";
    }

    function addTradingBot(uint param) public override {
        require(_tradingBotStates[msg.sender] == 0, "Trading bot already exists");
        require(param > 0, "Invalid param");

        _tradingBotStates[msg.sender] = param;
    }

    function update(uint latestPrice) public override {}   

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