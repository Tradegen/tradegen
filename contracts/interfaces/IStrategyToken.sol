pragma solidity >=0.4.24;

interface IStrategyToken {
    // Views
    function currencyKey() external view returns (bytes32);

    // Mutative functions
    function transferAndSettle(address to, uint value) external returns (bool);

    // Restricted: used internally to Tradegen
    function burn(address account, uint amount) external;

    function issue(address account, uint amount) external;
}