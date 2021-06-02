pragma solidity >=0.5.0;

//comparators
import './comparators/Closes.sol';
import './comparators/CrossesAbove.sol';
import './comparators/CrossesBelow.sol';
import './comparators/FallByAtLeast.sol';
import './comparators/FallByAtMost.sol';
import './comparators/FallsTo.sol';
import './comparators/IsAbove.sol';
import './comparators/IsBelow.sol';
import './comparators/RiseByAtLeast.sol';
import './comparators/RiseByAtMost.sol';
import './comparators/RisesTo.sol';

//indicators
import './indicators/Down.sol';
import './indicators/EMA.sol';
import './indicators/HighOfLastNPriceUpdates.sol';
import './indicators/Interval.sol';
import './indicators/LatestPrice.sol';
import './indicators/LowOfLastNPriceUpdates.sol';
import './indicators/NPercent.sol';
import './indicators/NthPriceUpdate.sol';
import './indicators/PreviousNPriceUpdates.sol';
import './indicators/SMA.sol';
import './indicators/Up.sol';

contract Imports {
    
    function _generateIndicator(uint indicator, uint param) internal returns (address) {
        if (indicator == 0)
        {
            return address(new Down());
        }
        else if (indicator == 1)
        {
            return address(new EMA(param));
        }
        else if (indicator == 2)
        {
            return address(new HighOfLastNPriceUpdates(param));
        }
        else if (indicator == 3)
        {
            return address(new Interval(param));
        }
        else if (indicator == 4)
        {
            return address(new LatestPrice());
        }
        else if (indicator == 5)
        {
            return address(new LowOfLastNPriceUpdates(param));
        }
        else if (indicator == 6)
        {
            return address(new NPercent(param));
        }
        else if (indicator == 7)
        {
            return address(new NthPriceUpdate(param));
        }
        else if (indicator == 8)
        {
            return address(new PreviousNPriceUpdates(param));
        }
        else if (indicator == 9)
        {
            return address(new SMA(param));
        }
        else if (indicator == 10)
        {
            return address(new Up());
        }

        return address(0);
    }

    function _generateComparator(uint comparator, address firstIndicatorAddress, address secondIndicatorAddress) internal returns (address) {
        if (comparator == 0)
        {
            return address(new Closes(firstIndicatorAddress, secondIndicatorAddress));
        }
        else if (comparator == 1)
        {
            return address(new CrossesAbove(firstIndicatorAddress, secondIndicatorAddress));
        }
        else if (comparator == 2)
        {
            return address(new CrossesBelow(firstIndicatorAddress, secondIndicatorAddress));
        }
        else if (comparator == 3)
        {
            return address(new FallByAtLeast(firstIndicatorAddress, secondIndicatorAddress));
        }
        else if (comparator == 4)
        {
            return address(new FallByAtMost(firstIndicatorAddress, secondIndicatorAddress));
        }
        else if (comparator == 5)
        {
            return address(new FallsTo(firstIndicatorAddress, secondIndicatorAddress));
        }
        else if (comparator == 6)
        {
            return address(new IsAbove(firstIndicatorAddress, secondIndicatorAddress));
        }
        else if (comparator == 7)
        {
            return address(new IsBelow(firstIndicatorAddress, secondIndicatorAddress));
        }
        else if (comparator == 8)
        {
            return address(new RiseByAtLeast(firstIndicatorAddress, secondIndicatorAddress));
        }
        else if (comparator == 9)
        {
            return address(new RiseByAtMost(firstIndicatorAddress, secondIndicatorAddress));
        }
        else if (comparator == 10)
        {
            return address(new RisesTo(firstIndicatorAddress, secondIndicatorAddress));
        }

        return address(0);
    }
}