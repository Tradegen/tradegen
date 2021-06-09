pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';

contract HighOfLastNPriceUpdates is IIndicator {

    struct State {
        uint8 N;
        uint128 currentValue;
        uint[] history;
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
        return "HighOfLastNPriceUpdates";
    }

    function addTradingBot(uint param) public override {
        require(_tradingBotStates[msg.sender].currentValue == 0, "Trading bot already exists");
        require(param > 1 && param <= 200, "Param must be between 2 and 200");

        _tradingBotStates[msg.sender] = State(uint8(param), 0, new uint[](0));
    }

    function update(uint latestPrice) public override {
        uint length = (_tradingBotStates[msg.sender].history.length >= uint256(_tradingBotStates[msg.sender].N)) ? uint256(_tradingBotStates[msg.sender].N) : 0;

        _tradingBotStates[msg.sender].history.push(latestPrice);

        uint high = 0;

        for (uint i = 0; i < length; i++)
        {
            high = (_tradingBotStates[msg.sender].history[length - i - 1] > high) ? _tradingBotStates[msg.sender].history[length - i - 1] : high;
        }

        _tradingBotStates[msg.sender].currentValue = uint128(high);
    }   

    function getValue(address tradingBotAddress) public view override returns (uint[] memory) {
        require(tradingBotAddress != address(0), "Invalid trading bot address");

        uint[] memory temp = new uint[](1);
        temp[0] = uint256(_tradingBotStates[tradingBotAddress].currentValue);
        return temp;
    }

    function getHistory(address tradingBotAddress) public view override returns (uint[] memory) {
        require(tradingBotAddress != address(0), "Invalid trading bot address");

        return _tradingBotStates[tradingBotAddress].history;
    }
}