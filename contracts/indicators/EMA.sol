pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';
import '../libraries/SafeMath.sol';

contract EMA is IIndicator {
    using SafeMath for uint;

    uint public currentValue;
    uint[] public priceHistory;
    uint[] public indicatorHistory;
    uint public EMAperiod;

    constructor(uint period) public {
        EMAperiod = period;
    }

    function getName() public pure override returns (string memory) {
        return "EMA";
    }

    function update(uint latestPrice) public override {
        priceHistory.push(latestPrice);

        if (priceHistory.length >= EMAperiod)
        {
            uint temp = 0;
            uint initialEMA = 0;
            uint multiplier = 2;
            multiplier = multiplier.div(EMAperiod.add(1));

            for (uint i = EMAperiod; i >= 1; i--)
            {
                if (i == EMAperiod)
                {
                    initialEMA = priceHistory[priceHistory.length - i];
                    temp = initialEMA;
                }
                else
                {
                    temp = multiplier.mul(priceHistory[priceHistory.length - i]).add((1 - multiplier).mul(initialEMA));
                    initialEMA = temp;
                }
            }

            currentValue = temp;
        }

        indicatorHistory.push(currentValue);
    }   

    function getValue() public view override returns (uint[] memory) {
        uint[] memory temp = new uint[](1);
        temp[0] = currentValue;
        return temp;
    }

    function getHistory() public view override returns (uint[] memory) {
        return indicatorHistory;
    }
}