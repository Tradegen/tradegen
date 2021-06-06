pragma solidity >=0.5.0;

import '../AddressResolver.sol';

import '../interfaces/IIndicator.sol';
import '../libraries/SafeMath.sol';

contract SMA is IIndicator, AddressResolver {
    using SafeMath for uint;

    uint public currentValue;
    uint[] public priceHistory;
    uint[] public indicatorHistory;
    uint public SMAperiod;
    uint public total;

    constructor(uint period) public onlyImports(msg.sender) {
        SMAperiod = period;
    }

    function getName() public pure override returns (string memory) {
        return "SMA";
    }

    function update(uint latestPrice) public override {
        priceHistory.push(latestPrice);
        total = total.add(latestPrice);

        if (priceHistory.length >= SMAperiod)
        {
            if (priceHistory.length > SMAperiod)
            {
                total = total.sub(priceHistory[priceHistory.length - SMAperiod]);
            }

            currentValue = total.div(SMAperiod);
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