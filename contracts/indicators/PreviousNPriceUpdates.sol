pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';

contract PreviousNPriceUpdates is IIndicator {
    uint public currentValue;
    uint[] public history;
    uint public N;

    constructor(uint numberOfPriceUpdates) public {
        N = numberOfPriceUpdates;
    }

    function getName() public pure override returns (string memory) {
        return "PreviousNPriceUpdates";
    }

    function update(uint latestPrice) public override {
        history.push(latestPrice);
    }   

    function getValue() public view override returns (uint[] memory) {
        uint length = (history.length >= N) ? N : 0;
        uint[] memory temp = new uint[](length);
        
        for (uint i = length; i >= 1; i--)
        {
            temp[length - i] = history[length - i];
        }
        return temp;
    }

    function getHistory() public view override returns (uint[] memory) {
        return history;
    }
}