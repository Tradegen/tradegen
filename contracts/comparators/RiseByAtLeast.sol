pragma solidity >=0.5.0;

import '../AddressResolver.sol';

import '../interfaces/IIndicator.sol';
import '../interfaces/IComparator.sol';

import '../libraries/SafeMath.sol';

contract RiseByAtLeast is IComparator, AddressResolver {
    using SafeMath for uint;

    address private _firstIndicatorAddress;
    address private _secondIndicatorAddress;

    constructor(address firstIndicatorAddress, address secondIndicatorAddress) public onlyImports(msg.sender) {
        _firstIndicatorAddress = firstIndicatorAddress;
        _secondIndicatorAddress = secondIndicatorAddress;
    }

    function checkConditions() public view override returns (bool) {
        uint[] memory firstIndicatorHistory = IIndicator(_firstIndicatorAddress).getValue();
        uint[] memory secondIndicatorHistory = IIndicator(_secondIndicatorAddress).getValue();

        if (firstIndicatorHistory.length == 0)
        {
            return false;
        }

        //check if indicator fell in value
        if (firstIndicatorHistory[firstIndicatorHistory.length] <= firstIndicatorHistory[0])
        {
            return false;
        }

        uint percentRise = firstIndicatorHistory[firstIndicatorHistory.length - 1].div(firstIndicatorHistory[0]);
        percentRise = percentRise.sub(1);
        percentRise = percentRise.mul(100);
        return (percentRise >= secondIndicatorHistory[0]);
    }
}