pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';
import '../interfaces/IComparator.sol';

contract Closes is IComparator {

    struct State {
        address firstIndicatorAddress;
        address secondIndicatorAddress;
        uint previousPrice;
    }

    mapping (address => State) private _tradingBotStates;

    function addTradingBot(address tradingBotAddress, address firstIndicatorAddress, address secondIndicatorAddress) public override {
        require(tradingBotAddress != address(0), "Invalid trading bot address");
        require(firstIndicatorAddress != address(0), "Invalid first indicator address");
        require(secondIndicatorAddress != address(0), "Invalid second indicator address");
        require(_tradingBotStates[tradingBotAddress].previousPrice == 0, "Trading bot already exists");

        _tradingBotStates[tradingBotAddress] = State(firstIndicatorAddress, secondIndicatorAddress, 0);
    }

    function checkConditions(address tradingBotAddress) public override returns (bool) {
        require(tradingBotAddress != address(0), "Invalid trading bot address");

        State storage tradingBotState = _tradingBotStates[tradingBotAddress];
        
        if (keccak256(bytes(IIndicator(tradingBotState.secondIndicatorAddress).getName())) == keccak256(bytes("Up")))
        {
            uint[] memory priceHistory = IIndicator(tradingBotState.firstIndicatorAddress).getValue(tradingBotAddress);

            if (priceHistory.length == 0)
            {
                return false;
            }

            if (keccak256(bytes(IIndicator(tradingBotState.firstIndicatorAddress).getName())) == keccak256(bytes("PreviousNPriceUpdates")))
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
                bool result = (priceHistory[0] > tradingBotState.previousPrice);
                tradingBotState.previousPrice = priceHistory[0];
                return result;
            }
        }
        else if (keccak256(bytes(IIndicator(tradingBotState.secondIndicatorAddress).getName())) == keccak256(bytes("Down")))
        {
            uint[] memory priceHistory = IIndicator(tradingBotState.firstIndicatorAddress).getValue(tradingBotAddress);

            if (priceHistory.length == 0)
            {
                return false;
            }

            if (keccak256(bytes(IIndicator(tradingBotState.firstIndicatorAddress).getName())) == keccak256(bytes("PreviousNPriceUpdates")))
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
                bool result = (priceHistory[0] < tradingBotState.previousPrice);
                tradingBotState.previousPrice = priceHistory[0];
                return result;
            }
        }

        return false;
    }
}