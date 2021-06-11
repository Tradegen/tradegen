pragma solidity >=0.5.0;

interface ITradingBot {

    struct Rule {
        address firstIndicatorAddress;
        address secondIndicatorAddress;
        address comparatorAddress;
    }

    function getTradingBotParameters() external view returns (Rule[] memory, Rule[] memory, uint, uint, uint, bool, address);
    function onPriceFeedUpdate(uint latestPrice) external;
    function getStrategyAddress() external view returns (address);
    function checkIfBotIsInATrade() external view returns (bool);
}