pragma solidity >=0.5.0;

interface IPool {

    struct PositionKeyAndBalance {
        address positionKey;
        uint balance;
    }

    struct InvestorAndBalance {
        address investor;
        uint balance;
    }

    function getPoolName() external view returns (string memory);
    function getManagerAddress() external view returns (address);
    function getInvestors() external view returns (InvestorAndBalance[] memory);
    function getPositionsAndTotal() external view returns (PositionKeyAndBalance[] memory, uint);
    function getAvailableFunds() external view returns (uint);
    function getPoolBalance() external view returns (uint);
    function getUserBalance(address user) external view returns (uint);
    function deposit(uint amount) external;
    function withdraw(address user, uint amount) external;
}