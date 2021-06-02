pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';
import '../interfaces/IComparator.sol';

import '../libraries/SafeMath.sol';

contract RisesTo is IComparator {
    using SafeMath for uint;

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

        uint previousLowerErrorBound = _secondIndicatorPreviousValue.mul(999).div(1000);
        uint currentLowerErrorBound = secondIndicatorHistory[secondIndicatorHistory.length - 1].mul(999).div(1000);
        uint currentUpperErrorBound = secondIndicatorHistory[secondIndicatorHistory.length - 1].mul(1001).div(1000);

        bool result = (_firstIndicatorPreviousValue < previousLowerErrorBound)
                    && (firstIndicatorHistory[firstIndicatorHistory.length - 1] >= currentLowerErrorBound)
                    && (firstIndicatorHistory[firstIndicatorHistory.length - 1] <= currentUpperErrorBound);
        _firstIndicatorPreviousValue = firstIndicatorHistory[firstIndicatorHistory.length - 1];
        _secondIndicatorPreviousValue = secondIndicatorHistory[secondIndicatorHistory.length - 1];
        return result;
    }
}