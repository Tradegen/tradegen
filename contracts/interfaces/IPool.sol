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
    function name() external view returns (string memory);

    /**
    * @dev Returns the address of the pool's farm
    * @return address Address of the pool's farm
    */
    function getFarmAddress() external view returns (address);

    /**
    * @dev Return the pool manager's address
    * @return address Address of the pool's manager
    */
    function getManagerAddress() external view returns (address);

    /**
    * @dev Returns the currency address and balance of each position the pool has, as well as the cumulative value
    * @return (address[], uint[], uint) Currency address and balance of each position the pool has, and the cumulative value of positions
    */
    function getPositionsAndTotal() external view returns (address[] memory, uint[] memory, uint);

    /**
    * @dev Returns the amount of stable coins the pool has to invest
    * @return uint Amount of stable coin the pool has available
    */
    function getAvailableFunds() external view returns (uint);

    /**
    * @dev Returns the value of the pool in USD
    * @return uint Value of the pool in USD
    */
    function getPoolValue() external view returns (uint);

    /**
    * @dev Returns the balance of the user in USD
    * @return uint Balance of the user in USD
    */
    function getUSDBalance(address user) external view returns (uint);

    /**
    * @dev Returns the number of pool tokens the user has
    * @param user Address of the user
    * @return uint Number of pool tokens the user has
    */
    function balanceOf(address user) external view returns (uint);

    /**
    * @dev Deposits the given USD amount into the pool
    * @notice Call cUSD.approve() before calling this function
    * @param amount Amount of USD to deposit into the pool
    */
    function deposit(uint amount) external;

    /**
    * @dev Withdraws the given number of pool tokens from the user
    * @param numberOfPoolTokens Number of pool tokens to withdraw
    */
    function withdraw(uint numberOfPoolTokens) external;

    /**
    * @dev Returns the pool's performance fee
    * @return uint The pool's performance fee
    */
    function getPerformanceFee() external view returns (uint);

    /**
    * @dev Updates the pool's farm address
    * @param farmAddress Address of the pool's farm
    */
    function setFarmAddress(address farmAddress) external;

    /**
    * @dev Returns the pool's USD value of the asset
    * @param asset Address of the asset
    * @param assetHandlerAddress Address of AssetHandler contract
    * @return uint Pool's USD value of the asset
    */
    function getAssetValue(address asset, address assetHandlerAddress) external view returns (uint);

    /**
    * @dev Returns the price of the pool's token
    * @return USD price of the pool's token
    */
    function tokenPrice() external view returns (uint);

    /**
    * @dev Returns the pool manager's available fees
    * @return Pool manager's available fees
    */
    function availableManagerFee() external view returns (uint);
}