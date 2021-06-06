pragma solidity >=0.5.0;

import '../AddressResolver.sol';

import '../interfaces/IIndicator.sol';

contract HighOfLastNPriceUpdates is IIndicator, AddressResolver {
    uint public currentValue;
    uint[] public history;
    uint public N;

    constructor(uint numberOfPriceUpdates) public onlyImports(msg.sender) {
        N = numberOfPriceUpdates;
    }

    function getName() public pure override returns (string memory) {
        return "HighOfLastNPriceUpdates";
    }

    function update(uint latestPrice) public override {
        history.push(latestPrice);

        uint high = 0;

        if (history.length >= N)
        {
            for (uint i = 0; i < N; i++)
            {
                high = (history[history.length - i - 1] > high) ? history[history.length - i - 1] : high;
            }
        }

        currentValue = high;
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