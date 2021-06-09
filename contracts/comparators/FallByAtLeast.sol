pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';
import '../interfaces/IComparator.sol';

import '../libraries/SafeMath.sol';

contract FallByAtLeast is IComparator {
    using SafeMath for uint;

    struct State {
        address firstIndicatorAddress;
        address secondIndicatorAddress;
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
        require(_tradingBotStates[msg.sender].firstIndicatorAddress == address(0), "Trading bot already exists");

        _tradingBotStates[msg.sender] = State(firstIndicatorAddress, secondIndicatorAddress);
    }

    function checkConditions() public view override returns (bool) {
        State storage tradingBotState = _tradingBotStates[msg.sender];

        uint[] memory firstIndicatorHistory = IIndicator(tradingBotState.firstIndicatorAddress).getValue(msg.sender);
        uint[] memory secondIndicatorHistory = IIndicator(tradingBotState.secondIndicatorAddress).getValue(msg.sender);

        if (firstIndicatorHistory.length == 0)
        {
            return false;
        }

        //check if indicator rose in value
        if (firstIndicatorHistory[firstIndicatorHistory.length] >= firstIndicatorHistory[0])
        {
            return false;
        }

        uint percentFall = 1;
        percentFall = percentFall.sub(firstIndicatorHistory[firstIndicatorHistory.length - 1].div(firstIndicatorHistory[0]));
        percentFall = percentFall.mul(100);
        return (percentFall >= secondIndicatorHistory[0]);
    }
}