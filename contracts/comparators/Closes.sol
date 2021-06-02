pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';
import '../interfaces/IComparator.sol';

contract Closes is IComparator {

    address private _firstIndicatorAddress;
    address private _secondIndicatorAddress;
    uint private _previousPrice;

    constructor(address firstIndicatorAddress, address secondIndicatorAddress) public {
        _firstIndicatorAddress = firstIndicatorAddress;
        _secondIndicatorAddress = secondIndicatorAddress;
        _previousPrice = 0;
    }

    function checkConditions() public override returns (bool) {
        if (keccak256(bytes(IIndicator(_secondIndicatorAddress).getName())) == keccak256(bytes("Up")))
        {
            uint[] memory priceHistory = IIndicator(_firstIndicatorAddress).getValue();

            if (priceHistory.length == 0)
            {
                return false;
            }

            if (keccak256(bytes(IIndicator(_firstIndicatorAddress).getName())) == keccak256(bytes("PreviousNPriceUpdates")))
            {
                for (uint i = 1; i < priceHistory.length; i++)
                {
                    if (priceHistory[i] <= priceHistory[i - 1])
                    {
                        return false;
                    }
                }

                return true;
            }
            else
            {
                bool result = (priceHistory[0] > _previousPrice);
                _previousPrice = priceHistory[0];
                return result;
            }
        }
        else if (keccak256(bytes(IIndicator(_secondIndicatorAddress).getName())) == keccak256(bytes("Down")))
        {
            uint[] memory priceHistory = IIndicator(_firstIndicatorAddress).getValue();

            if (priceHistory.length == 0)
            {
                return false;
            }

            if (keccak256(bytes(IIndicator(_firstIndicatorAddress).getName())) == keccak256(bytes("PreviousNPriceUpdates")))
            {
                for (uint i = 1; i < priceHistory.length; i++)
                {
                    if (priceHistory[i] >= priceHistory[i - 1])
                    {
                        return false;
                    }
                }

                return true;
            }
            else
            {
                bool result = (priceHistory[0] < _previousPrice);
                _previousPrice = priceHistory[0];
                return result;
            }
        }

        return false;
    }
}