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

    /**
    * @dev Returns the name of the pool
    * @return string The name of the pool
    */
    function getPoolName() external view returns (string memory);

    /**
    * @dev Return the pool manager's address
    * @return address Address of the pool's manager
    */
    function getManagerAddress() external view returns (address);

    /**
    * @dev Returns the name and address of each investor in the pool
    * @return InvestorAndBalance[] The address and balance of each investor in the pool
    */
    function getInvestors() external view returns (InvestorAndBalance[] memory);

    /**
    * @dev Returns the currency address and balance of each position the pool has, as well as the cumulative value
    * @return (PositionKeyAndBalance[], uint) Currency address and balance of each position the pool has, and the cumulative value of positions
    */
    function getPositionsAndTotal() external view returns (PositionKeyAndBalance[] memory, uint);

    /**
    * @dev Returns the amount of stable coins the pool has to invest
    * @return uint Amount of stable coin the pool has available
    */
    function getAvailableFunds() external view returns (uint);

    /**
    * @dev Returns the value of the pool in USD
    * @return uint Value of the pool in USD
    */
    function getPoolBalance() external view returns (uint);

    /**
    * @dev Returns the balance of the user in USD
    * @return uint Balance of the user in USD
    */
    function getUserBalance(address user) external view returns (uint);

    /**
    * @dev Returns the number of LP tokens the user has
    * @param user Address of the user
    * @return uint Number of LP tokens the user has
    */
    function getUserTokenBalance(address user) external view returns (uint);

    /**
    * @dev Deposits the given USD amount into the pool
    * @param amount Amount of USD to deposit into the pool
    */
    function deposit(uint amount) external;

    /**
    * @dev Withdraws the given USD amount on behalf of the user
    * @param user Address of user to withdraw
    * @param amount Amount of USD to withdraw from the pool
    */
    function withdraw(address user, uint amount) external;

    /**
    * @dev Places an order to buy/sell the given currency
    * @param currencyKey Address of currency to trade
    * @param buyOrSell Whether the user is buying or selling
    * @param numberOfTokens Number of tokens of the given currency
    */
    function placeOrder(address currencyKey, bool buyOrSell, uint numberOfTokens) external;
}