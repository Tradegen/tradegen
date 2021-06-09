pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';
import '../libraries/SafeMath.sol';

contract SMA is IIndicator {
    using SafeMath for uint;

    struct State {
        uint8 SMAperiod;
        uint128 currentValue;
        uint[] priceHistory;
        uint[] indicatorHistory;
    }

    uint public _price;
    address public _developer;

    mapping (address => State) private _tradingBotStates;

    constructor(uint price) public {
        require(price >= 0, "Price must be greater than 0");

        _price = price;
        _developer = msg.sender;
    }

    function getName() public pure override returns (string memory) {
        return "SMA";
    }

    function addTradingBot(uint param) public override {
        require(_tradingBotStates[msg.sender].currentValue == 0, "Trading bot already exists");
        require(param > 1 && param <= 200, "Param must be between 2 and 200");

        _tradingBotStates[msg.sender] = State(uint8(param), 0, new uint[](0), new uint[](0));
    }

    function update(uint latestPrice) public override {
        _tradingBotStates[msg.sender].priceHistory.push(latestPrice);

        if ( _tradingBotStates[msg.sender].priceHistory.length >= uint256(_tradingBotStates[msg.sender].SMAperiod))
        {
            uint temp = uint256(_tradingBotStates[msg.sender].currentValue).mul(uint256(_tradingBotStates[msg.sender].SMAperiod));
            temp = temp.sub(_tradingBotStates[msg.sender].priceHistory[_tradingBotStates[msg.sender].priceHistory.length - uint256(_tradingBotStates[msg.sender].SMAperiod)]);
            temp = temp.add(latestPrice);
            temp = temp.div(uint256(_tradingBotStates[msg.sender].SMAperiod));
            _tradingBotStates[msg.sender].currentValue = uint128(temp);
        }

        _tradingBotStates[msg.sender].indicatorHistory.push(_tradingBotStates[msg.sender].currentValue);
    }   

    function getValue(address tradingBotAddress) public view override returns (uint[] memory) {
        require(tradingBotAddress != address(0), "Invalid trading bot address");

        State storage tradingBotState = _tradingBotStates[tradingBotAddress];

        uint[] memory temp = new uint[](1);
        temp[0] = tradingBotState.currentValue;
        return temp;
    }

    function getHistory(address tradingBotAddress) public view override returns (uint[] memory) {
        require(tradingBotAddress != address(0), "Invalid trading bot address");

        State storage tradingBotState = _tradingBotStates[tradingBotAddress];

        return tradingBotState.indicatorHistory;
    }
}