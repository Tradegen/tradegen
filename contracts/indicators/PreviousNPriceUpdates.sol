pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';

contract PreviousNPriceUpdates is IIndicator {

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
        return "PreviousNPriceUpdates";
    }

    function addTradingBot(uint param) public override {
        require(_tradingBotStates[msg.sender].currentValue == 0, "Trading bot already exists");
        require(param > 1 && param <= 200, "Param must be between 2 and 200");

        _tradingBotStates[msg.sender] = State(uint8(param), 0, new uint[](0));
    }

    function update(uint latestPrice) public override {
        _tradingBotStates[msg.sender].history.push(latestPrice);
    }   

    function getValue(address tradingBotAddress) public view override returns (uint[] memory) {
        require(tradingBotAddress != address(0), "Invalid trading bot address");
        
        uint length = (_tradingBotStates[tradingBotAddress].history.length >= uint256(_tradingBotStates[tradingBotAddress].N)) ? uint256(_tradingBotStates[tradingBotAddress].N) : 0;
        uint[] memory temp = new uint[](length);

        for (uint i = length; i >= 1; i--)
        {
            temp[length - i] = _tradingBotStates[tradingBotAddress].history[length - i];
        }

        return temp;
    }

    function getHistory(address tradingBotAddress) public view override returns (uint[] memory) {
        require(tradingBotAddress != address(0), "Invalid trading bot address");

        return _tradingBotStates[tradingBotAddress].history;
    }
}