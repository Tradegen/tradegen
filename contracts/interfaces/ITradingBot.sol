pragma solidity >=0.5.0;

interface ITradingBot {
    function getTradingBotParameters() external view returns (uint[] memory, uint[] memory, uint, uint, uint, bool, string memory);
    function onPriceFeedUpdate(uint latestPrice) external;
    function getStrategyAddress() external view returns (address);
}