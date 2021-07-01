pragma solidity >=0.5.0;

interface IIndicator {

    /**
    * @dev Returns the name of the indicator
    * @return string Name of the indicator
    */
    function getName() external pure returns (string memory);

    /**
    * @dev Returns the sale price and the developer of the indicator
    * @return (uint, address) Sale price of the indicator and the indicator's developer
    */
    function getPriceAndDeveloper() external view returns (uint, address);

    /**
    * @dev Updates the sale price of the indicator; meant to be called by the indicator's developer
    * @param newPrice The new sale price of the indicator
    */
    function editPrice(uint newPrice) external;

    /**
    * @dev Initializes the state of the trading bot; meant to be called by a trading bot
    * @param param Value of the indicator's parameter
    */
    function addTradingBot(uint param) external;

    /**
    * @dev Updates the indicator's state based on the latest price feed update
    * @param latestPrice The latest price from oracle price feed
    */
    function update(uint latestPrice) external;

    /**
    * @dev Given a trading bot address, returns the indicator value for that bot
    * @param tradingBotAddress Address of trading bot
    * @return uint[] Indicator value for the given trading bot
    */
    function getValue(address tradingBotAddress) external view returns (uint[] memory);

    /**
    * @dev Given a trading bot address, returns the indicator value history for that bot
    * @param tradingBotAddress Address of trading bot
    * @return uint[] Indicator value history for the given trading bot
    */
    function getHistory(address tradingBotAddress) external view returns (uint[] memory);

    // Events
    event UpdatedPrice(address indexed indicatorAddress, uint newPrice, uint timestamp);
}