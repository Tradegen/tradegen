pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';
import '../interfaces/IComparator.sol';

contract Closes is IComparator {

    struct State {
        address firstIndicatorAddress;
        address secondIndicatorAddress;
        uint248 previousPrice;
        bool exists;
    }

    uint public _price;
    address public _developer;

    mapping (address => mapping(uint => State)) private _tradingBotStates;

    constructor(uint price) public {
        require(price >= 0, "Price must be greater than 0");

        _price = price;
        _developer = msg.sender;
    }

    /**
    * @dev Returns the sale price and the developer of the comparator
    * @return (uint, address) Sale price of the comparator and the comparator's developer
    */
    function getPriceAndDeveloper() public view override returns (uint, address) {
        return (_price, _developer);
    }

    /**
    * @dev Updates the sale price of the comparator; meant to be called by the comparator developer
    * @param newPrice The new sale price of the comparator
    */
    function editPrice(uint newPrice) external override {
        require(msg.sender == _developer, "Only the developer can edit the price");
        require(newPrice >= 0, "Price must be a positive number");

        _price = newPrice;

        emit UpdatedPrice(address(this), newPrice, block.timestamp);
    }

    /**
    * @dev Initializes the state of the trading bot; meant to be called by a trading bot
    * @param index Index in trading bot's entry/exit rule array
    * @param firstIndicatorAddress Address of the comparator's first indicator
    * @param secondIndicatorAddress Address of the comparator's second indicator
    */
    function addTradingBot(uint index, address firstIndicatorAddress, address secondIndicatorAddress) public override {
        require(index > 0, "Invalid index");
        require(firstIndicatorAddress != address(0), "Invalid first indicator address");
        require(secondIndicatorAddress != address(0), "Invalid second indicator address");
        require(!_tradingBotStates[msg.sender][index].exists, "Trading bot already exists");

        _tradingBotStates[msg.sender][index] = State(firstIndicatorAddress, secondIndicatorAddress, 0, true);
    }

    /**
    * @dev Returns whether the comparator's conditions are met
    * @notice Only 'Up' and 'Down' are compatible second indicators
    * @param index Index in trading bot's entry/exit rule array
    * @return bool Whether the comparator's conditions are met after the latest price feed update
    */
    function checkConditions(uint index) public override returns (bool) {
        require(index > 0, "Invalid index");
        require(_tradingBotStates[msg.sender][index].exists, "Trading bot doesn't exist");

        State storage tradingBotState = _tradingBotStates[msg.sender][index];
        uint[] memory priceHistory = IIndicator(tradingBotState.firstIndicatorAddress).getValue(msg.sender, index);
        
        if (keccak256(bytes(IIndicator(tradingBotState.secondIndicatorAddress).getName())) == keccak256(bytes("Up")))
        {
            if (priceHistory.length == 0)
            {
                return false;
            }

            if (priceHistory.length > 1)
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
                tradingBotState.previousPrice = uint248(priceHistory[0]);
                return result;
            }
        }
        else if (keccak256(bytes(IIndicator(tradingBotState.secondIndicatorAddress).getName())) == keccak256(bytes("Down")))
        {
            if (priceHistory.length == 0)
            {
                return false;
            }

            if (priceHistory.length > 1)
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
                tradingBotState.previousPrice = uint248(priceHistory[0]);
                return result;
            }
        }

        return false;
    }
}