pragma solidity >=0.4.24;

interface IExchangeRates {
    // Views
    function oracle() external view returns (address);

    function rateForCurrency(bytes32 currencyKey) external view returns (uint);

    function ratesForCurrencies(bytes32[] calldata currencyKeys) external view returns (uint[] memory);
}