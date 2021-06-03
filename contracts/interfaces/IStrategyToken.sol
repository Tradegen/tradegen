pragma solidity >=0.5.0;

interface IStrategyToken {
    function _getStrategyDetails() external view returns (string memory, string memory, string memory, address, uint, uint, uint, uint);
    function _getPositionDetails(address _user) external view returns (string memory, string memory, uint, uint, uint);
    function buyPosition(address from, address to, uint numberOfTokens) external;
    function deposit(address _user, uint amount) external;
    function withdraw(address _user, uint amount) external;
    function getTradingBotAddress() external view returns (address);
    function getBalanceOf(address user) external view returns (uint);
}