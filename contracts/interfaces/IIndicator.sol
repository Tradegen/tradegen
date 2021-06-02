pragma solidity >=0.5.0;

interface IIndicator {

    function getName() external pure returns (string memory);

    function update(uint latestPrice) external;

    function getValue() external view returns (uint[] memory);

    function getHistory() external view returns (uint[] memory);
}