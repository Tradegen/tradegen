pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';
import '../interfaces/IComparator.sol';

contract CrossesBelow is IComparator {

    address private _firstIndicatorAddress;
    address private _secondIndicatorAddress;
    uint private _firstIndicatorPreviousValue;
    uint private _secondIndicatorPreviousValue;

    constructor(address firstIndicatorAddress, address secondIndicatorAddress) public {
        _firstIndicatorAddress = firstIndicatorAddress;
        _secondIndicatorAddress = secondIndicatorAddress;
    }

    function checkConditions() public override returns (bool) {
        uint[] memory firstIndicatorHistory = IIndicator(_firstIndicatorAddress).getValue();
        uint[] memory secondIndicatorHistory = IIndicator(_secondIndicatorAddress).getValue();

        if (firstIndicatorHistory.length == 0 || secondIndicatorHistory.length == 0)
        {
            return false;
        }

        bool result = (_firstIndicatorPreviousValue > _secondIndicatorPreviousValue) &&
                    (firstIndicatorHistory[firstIndicatorHistory.length - 1] < secondIndicatorHistory[secondIndicatorHistory.length - 1]);
        _firstIndicatorPreviousValue = firstIndicatorHistory[firstIndicatorHistory.length - 1];
        _secondIndicatorPreviousValue = secondIndicatorHistory[secondIndicatorHistory.length - 1];
        return result;
    }
}