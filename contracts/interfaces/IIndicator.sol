pragma solidity >=0.5.0;

interface IIndicator {

    function getName() external pure returns (string memory);
    function getPriceAndDeveloper() external view returns (uint, address);
    function editPrice(uint newPrice) external;
    function addTradingBot(uint param) external; //anyone can call this function but it only works if trading bot calls it
    function update(uint latestPrice) external;
    function getValue(address tradingBotAddress) external view returns (uint[] memory);
    function getHistory(address tradingBotAddress) external view returns (uint[] memory);

    // Events
    event UpdatedPrice(address indexed indicatorAddress, uint newPrice, uint timestamp);
}