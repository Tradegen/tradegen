pragma solidity >=0.5.0;

interface IIndicator {

    function getName() external pure returns (string memory);

    function addTradingBot(uint param) external; //anyone can call this function but it only works if trading bot calls it

    function update(uint latestPrice) external;

    function getValue(address tradingBotAddress) external view returns (uint[] memory);

    function getHistory(address tradingBotAddress) external view returns (uint[] memory);
}