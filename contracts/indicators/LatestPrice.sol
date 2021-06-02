pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';

contract LatestPrice is IIndicator {
    uint public currentValue;
    uint[] public history;

    constructor() public {}

    function getName() public pure override returns (string memory) {
        return "LatestPrice";
    }

    function update(uint latestPrice) public override {
        currentValue = latestPrice;
        history.push(latestPrice);
    }   

    function getValue() public view override returns (uint[] memory) {
        uint[] memory temp = new uint[](1);
        temp[0] = currentValue;
        return temp;
    }

    function getHistory() public view override returns (uint[] memory) {
        return history;
    }
}