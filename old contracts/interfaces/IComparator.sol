pragma solidity >=0.5.0;

interface IComparator {

    /**
    * @dev Returns the sale price and the developer of the comparator
    * @return (uint, address) Sale price of the comparator and the comparator's developer
    */
    function getPriceAndDeveloper() external view returns (uint, address);

    /**
    * @dev Updates the sale price of the comparator; meant to be called by the comparator developer
    * @param newPrice The new sale price of the comparator
    */
    function editPrice(uint newPrice) external;

    /**
    * @dev Initializes the state of the trading bot; meant to be called by a trading bot
    * @param firstIndicatorAddress Address of the comparator's first indicator
    * @param secondIndicatorAddress Address of the comparator's second indicator
    */
    function addTradingBot(address firstIndicatorAddress, address secondIndicatorAddress) external;

    /**
    * @dev Returns whether the comparator's conditions are met
    * @return bool Whether the comparator's conditions are met after the latest price feed update
    */
    function checkConditions() external returns (bool);

    // Events
    event UpdatedPrice(address indexed comparatorAddress, uint newPrice, uint timestamp);
}