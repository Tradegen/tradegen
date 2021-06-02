pragma solidity >=0.4.24;

import "./IStrategyToken.sol";

interface ITradegen {
    // Views
    function availableCurrencyKeys() external view returns (bytes32[] memory);

    function availableStrategies(uint index) external view returns (IStrategyToken);

    function strategyTokens(bytes32 currencyKey) external view returns (IStrategyToken);

    function strategyTokensByAddress(address synthAddress) external view returns (bytes32);

    function totalIssuedStrategyTokens(bytes32 currencyKey) external view returns (uint);

    // Mutative Functions
    function burnStrategyTokens(uint amount) external;

    function exchange(
        bytes32 sourceCurrencyKey,
        uint sourceAmount,
        bytes32 destinationCurrencyKey
    ) external returns (uint amountReceived);

    function issueStrategyTokens(uint amount) external;
}