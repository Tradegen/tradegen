pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';

contract NthPriceUpdate is IIndicator {
    uint public currentValue;
    uint[] public indicatorHistory;
    uint[] public priceHistory;
    uint public N;

    constructor(uint numberOfPriceUpdates) public {
        N = numberOfPriceUpdates;
    }

    function getName() public pure override returns (string memory) {
        return "NthPriceUpdate";
    }

    function update(uint latestPrice) public override {
        priceHistory.push(latestPrice);
        indicatorHistory.push((N <= priceHistory.length) ? priceHistory[priceHistory.length - N] : 0);
    }   

    function getValue() public view override returns (uint[] memory) {
        uint[] memory temp = new uint[](1);
        temp[0] = (indicatorHistory.length > 0) ? indicatorHistory[indicatorHistory.length - 1] : 0;
        return temp;
    }

    function getHistory() public view override returns (uint[] memory) {
        return indicatorHistory;
    }
}