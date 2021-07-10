pragma solidity >=0.5.0;

interface IFeePool {

    /**
    * @notice Returns the amount of transaction fees available for the user
    * @param account Address of the user
    * @return uint Amount of available transaction fees
    */
    function getAvailableTransactionFees(address account) external view returns (uint);

    /**
    * @notice Adds transaction fees to the strategy's developer
    * @notice Function gets called by StrategyProxy whenever users invest in the strategy or buys a position from the marketplace
    * @param account Address of the user
    * @param amount Amount of TGEN to add
    */
    function addTransactionFees(address account, uint amount) external;

    /**
    * @notice Allow a user to claim any available transaction fees
    */
    function claimTransactionFees() external;
}