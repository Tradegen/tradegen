pragma solidity >=0.5.0;

import '../interfaces/IIndicator.sol';

contract HighOfLastNPriceUpdates is IIndicator {

    struct State {
        bool exists;
        uint8 N;
        uint120 currentValue;
        uint[] history;
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
    * @dev Returns the name of the indicator
    * @return string Name of the indicator
    */
    function getName() public pure override returns (string memory) {
        return "HighOfLastNPriceUpdates";
    }

    /**
    * @dev Returns the sale price and the developer of the indicator
    * @return (uint, address) Sale price of the indicator and the indicator's developer
    */
    function getPriceAndDeveloper() public view override returns (uint, address) {
        return (_price, _developer);
    }

    /**
    * @dev Updates the sale price of the indicator; meant to be called by the indicator's developer
    * @param newPrice The new sale price of the indicator
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
    * @param param Value of the indicator's parameter
    */
    function addTradingBot(uint index, uint param) public override {
        require(index > 0, "Invalid index");
        require(!_tradingBotStates[msg.sender][index].exists, "Trading bot already exists");
        require(param > 1 && param <= 200, "Param must be between 2 and 200");

        _tradingBotStates[msg.sender][index] = State(true, uint8(param), 0, new uint[](0));
    }

    /**
    * @dev Updates the indicator's state based on the latest price feed update
    * @param index Index in trading bot's entry/exit rule array
    * @param latestPrice The latest price from oracle price feed
    */
    function update(uint index, uint latestPrice) public override {
        require(index > 0, "Invalid index");
        require(_tradingBotStates[msg.sender][index].exists, "Trading bot doesn't exist");

        _tradingBotStates[msg.sender][index].history.push(latestPrice);
        uint length = (_tradingBotStates[msg.sender][index].history.length >= uint256(_tradingBotStates[msg.sender][index].N)) ? uint256(_tradingBotStates[msg.sender][index].N) : 0;

        uint high = 0;

        for (uint i = 0; i < length; i++)
        {
            high = (_tradingBotStates[msg.sender][index].history[_tradingBotStates[msg.sender][index].history.length - i - 1] > high) ? _tradingBotStates[msg.sender][index].history[_tradingBotStates[msg.sender][index].history.length - i - 1] : high;
        }

        _tradingBotStates[msg.sender][index].currentValue = uint120(high);
    }   

    /**
    * @dev Given a trading bot address, returns the indicator value for that bot
    * @param tradingBotAddress Address of trading bot
    * @param index Index in trading bot's entry/exit rule array
    * @return uint[] Indicator value for the given trading bot
    */
    function getValue(address tradingBotAddress, uint index) public view override returns (uint[] memory) {
        require(tradingBotAddress != address(0), "Invalid trading bot address");
        require(index > 0, "Invalid index");
        require(_tradingBotStates[msg.sender][index].exists, "Trading bot doesn't exist");

        uint[] memory temp = new uint[](1);
        temp[0] = uint256(_tradingBotStates[tradingBotAddress][index].currentValue);
        return temp;
    }

    /**
    * @dev Given a trading bot address, returns the indicator value history for that bot
    * @param tradingBotAddress Address of trading bot
    * @param index Index in trading bot's entry/exit rule array
    * @return uint[] Indicator value history for the given trading bot
    */
    function getHistory(address tradingBotAddress, uint index) public view override returns (uint[] memory) {
        require(tradingBotAddress != address(0), "Invalid trading bot address");
        require(index > 0, "Invalid index");
        require(_tradingBotStates[msg.sender][index].exists, "Trading bot doesn't exist");

        return _tradingBotStates[tradingBotAddress][index].history;
    }
}