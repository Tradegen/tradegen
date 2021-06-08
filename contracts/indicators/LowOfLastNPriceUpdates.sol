pragma solidity >=0.5.0;

import '../Ownable.sol';

import '../interfaces/IIndicator.sol';

contract LowOfLastNPriceUpdates is IIndicator, Ownable {

    struct State {
        uint8 N;
        uint128 currentValue;
        uint[] history;
    }

    mapping (address => State) private _tradingBotStates;

    constructor() public Ownable() {}

    function getName() public pure override returns (string memory) {
        return "LowOfLastNPriceUpdates";
    }

    function addTradingBot(address tradingBotAddress, uint param) public override onlyOwner() {
        require(tradingBotAddress != address(0), "Invalid trading bot address");
        require(_tradingBotStates[tradingBotAddress].currentValue == 0, "Trading bot already exists");
        require(param > 1 && param <= 200, "Param must be between 2 and 200");

        _tradingBotStates[tradingBotAddress] = State(uint8(param), 0, new uint[](0));
    }

    function update(address tradingBotAddress, uint latestPrice) public override {
        require(tradingBotAddress != address(0), "Invalid trading bot address");

        uint length = (_tradingBotStates[tradingBotAddress].history.length >= uint256(_tradingBotStates[tradingBotAddress].N)) ? uint256(_tradingBotStates[tradingBotAddress].N) : 0;

        _tradingBotStates[tradingBotAddress].history.push(latestPrice);

        uint low = 9999999999999999;

        for (uint i = 0; i < length; i++)
        {
            low = (_tradingBotStates[tradingBotAddress].history[length - i - 1] < low) ? _tradingBotStates[tradingBotAddress].history[length - i - 1] : low;
        }

        _tradingBotStates[tradingBotAddress].currentValue = uint128(low);
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