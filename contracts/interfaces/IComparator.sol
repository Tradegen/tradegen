pragma solidity >=0.5.0;

interface IComparator {

    function getPriceAndDeveloper() external view returns (uint, address);
    function editPrice(uint newPrice) external;
    function addTradingBot(address firstIndicatorAddress, address secondIndicatorAddress) external; //anyone can call this function but it only works if trading bot calls it
    function checkConditions() external returns (bool);

    // Events
    event UpdatedPrice(address indexed comparatorAddress, uint newPrice, uint timestamp);
}