pragma solidity >=0.5.0;

interface IRule {

    function update(uint latestPrice) external;

    function checkConditions() external returns (bool);
}