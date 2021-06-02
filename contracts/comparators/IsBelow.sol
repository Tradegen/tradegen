pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';
import '../interfaces/IComparator.sol';

contract IsBelow is IComparator {

    address private _firstIndicatorAddress;
    address private _secondIndicatorAddress;

    constructor(address firstIndicatorAddress, address secondIndicatorAddress) public {
        _firstIndicatorAddress = firstIndicatorAddress;
        _secondIndicatorAddress = secondIndicatorAddress;
    }

    function checkConditions() public override returns (bool) {
        uint[] memory firstIndicatorPriceHistory = IIndicator(_firstIndicatorAddress).getValue();
        uint[] memory secondIndicatorPriceHistory = IIndicator(_secondIndicatorAddress).getValue();

        if (firstIndicatorPriceHistory.length == 0 || secondIndicatorPriceHistory.length == 0)
        {
            return false;
        }

        return (firstIndicatorPriceHistory[firstIndicatorPriceHistory.length - 1] < secondIndicatorPriceHistory[secondIndicatorPriceHistory.length - 1]);
    }
}