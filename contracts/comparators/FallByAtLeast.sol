pragma solidity >=0.5.0;

import '../Ownable.sol';

import '../interfaces/IIndicator.sol';
import '../interfaces/IComparator.sol';

import '../libraries/SafeMath.sol';

contract FallByAtLeast is IComparator, Ownable {
    using SafeMath for uint;

    struct State {
        address firstIndicatorAddress;
        address secondIndicatorAddress;
    }

    mapping (address => State) private _tradingBotStates;

    constructor() public Ownable() {}

    function addTradingBot(address tradingBotAddress, address firstIndicatorAddress, address secondIndicatorAddress) public override onlyOwner() {
        require(tradingBotAddress != address(0), "Invalid trading bot address");
        require(firstIndicatorAddress != address(0), "Invalid first indicator address");
        require(secondIndicatorAddress != address(0), "Invalid second indicator address");
        require(_tradingBotStates[tradingBotAddress].firstIndicatorAddress == address(0), "Trading bot already exists");

        _tradingBotStates[tradingBotAddress] = State(firstIndicatorAddress, secondIndicatorAddress);
    }

    function checkConditions(address tradingBotAddress) public view override returns (bool) {
        require(tradingBotAddress != address(0), "Invalid trading bot address");

        State storage tradingBotState = _tradingBotStates[tradingBotAddress];

        uint[] memory firstIndicatorHistory = IIndicator(tradingBotState.firstIndicatorAddress).getValue(tradingBotAddress);
        uint[] memory secondIndicatorHistory = IIndicator(tradingBotState.secondIndicatorAddress).getValue(tradingBotAddress);

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