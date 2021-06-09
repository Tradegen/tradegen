pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';
import '../interfaces/IComparator.sol';

contract Closes is IComparator {

    struct State {
        address firstIndicatorAddress;
        address secondIndicatorAddress;
        uint previousPrice;
    }

    uint public _price;
    address public _developer;

    mapping (address => State) private _tradingBotStates;

    constructor(uint price) public {
        require(price >= 0, "Price must be greater than 0");

        _price = price;
        _developer = msg.sender;
    }

    function addTradingBot(address firstIndicatorAddress, address secondIndicatorAddress) public override {
        require(firstIndicatorAddress != address(0), "Invalid first indicator address");
        require(secondIndicatorAddress != address(0), "Invalid second indicator address");
        require(_tradingBotStates[msg.sender].previousPrice == 0, "Trading bot already exists");

        _tradingBotStates[msg.sender] = State(firstIndicatorAddress, secondIndicatorAddress, 0);
    }

    function checkConditions() public override returns (bool) {
        State storage tradingBotState = _tradingBotStates[msg.sender];
        
        if (keccak256(bytes(IIndicator(tradingBotState.secondIndicatorAddress).getName())) == keccak256(bytes("Up")))
        {
            uint[] memory priceHistory = IIndicator(tradingBotState.firstIndicatorAddress).getValue(msg.sender);

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
            uint[] memory priceHistory = IIndicator(tradingBotState.firstIndicatorAddress).getValue(msg.sender);

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