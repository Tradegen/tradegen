pragma solidity >=0.5.0;

interface IIndicator {

    function getName() external pure returns (string memory);

    function addTradingBot(address tradingBotAddress, uint param) external;

    function update(address tradingBotAddress, uint latestPrice) external;

    function getValue(address tradingBotAddress) external view returns (uint[] memory);

    function getHistory(address tradingBotAddress) external view returns (uint[] memory);
}