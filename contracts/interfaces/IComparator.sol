pragma solidity >=0.5.0;

interface IComparator {

    function addTradingBot(address tradingBotAddress, address firstIndicatorAddress, address secondIndicatorAddress) external;
    function checkConditions(address tradingBotAddress) external returns (bool);
}