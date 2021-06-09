pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';

contract Down is IIndicator {

    uint public _price;
    address public _developer;

    constructor(uint price) public {
        require(price >= 0, "Price must be greater than 0");

        _price = price;
        _developer = msg.sender;
    }

    function getName() public pure override returns (string memory) {
        return "Down";
    }

    function addTradingBot(uint param) public pure override {}

    function update(uint latestPrice) public override {}   

    function getValue(address tradingBotAddress) public pure override returns (uint[] memory) {
        uint[] memory temp = new uint[](1);
        temp[0] = 0;
        return temp;
    }

    function getHistory(address tradingBotAddress) public pure override returns (uint[] memory) {
        return new uint[](0);
    }
}