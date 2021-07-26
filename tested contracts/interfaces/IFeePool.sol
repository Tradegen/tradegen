pragma solidity >=0.5.0;

interface IFeePool {

    /**
    * @notice Returns the number of fee tokens the user has
    * @param account Address of the user
    * @return uint Number of fee tokens
    */
    function getTokenBalance(address account) external view returns (uint);

    /**
    * @notice Adds fees to user
    * @notice Function gets called by Pool whenever users withdraw for a profit
    * @param user Address of the user
    * @param feeAmount USD value of fee
    */
    function addFees(address user, uint feeAmount) external;

    /**
    * @notice Allow a user to claim available fees in the specified currency
    * @param currencyKey Address of the currency to claim 
    * @param numberOfTokens Number of tokens to claim in the given currency
    */
    function claimAvailableFees(address currencyKey, uint numberOfTokens) external;

    /**
    * @dev Returns the currency address and balance of each position the pool has, as well as the cumulative value
    * @return (address[], uint[], uint) Currency address and balance of each position the pool has, and the cumulative value of positions
    */
    function getPositionsAndTotal() external view returns (address[] memory, uint[] memory, uint);

    /**
    * @dev Returns the value of the pool in USD
    * @return uint Value of the pool in USD
    */
    function getPoolBalance() external view returns (uint);

    /**
    * @dev Returns the balance of the user in USD
    * @return uint Balance of the user in USD
    */
    function getUSDBalance(address user) external view returns (uint);

    /**
    * @notice Adds currency key to positionKeys array if no position yet
    * @notice Function gets called by Pool whenever users pay performance fee
    * @param positions Address of each position the pool/bot had when paying fee
    */
    function addPositionKeys(address[] memory positions) external;
}