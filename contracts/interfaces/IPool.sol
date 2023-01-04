// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IPool {
    /**
    * @notice Returns the name of the pool.
    */
    function name() external view returns (string memory);

    /**
    * @notice Return the pool manager's address.
    */
    function getManagerAddress() external view returns (address);

    /**
    * @notice Returns the currency address and balance of each position the pool has, as well as the cumulative value.
    * @return (address[], uint[], uint) Currency address and balance of each position the pool has, and the cumulative value of positions.
    */
    function getPositionsAndTotal() external view returns (address[] memory, uint[] memory, uint);

    /**
    * @notice Returns the amount of stable coins the pool has to invest.
    */
    function getAvailableFunds() external view returns (uint);

    /**
    * @notice Returns the value of the pool in USD.
    */
    function getPoolValue() external view returns (uint);

    /**
    * @notice Returns the balance of the user in USD.
    * @dev Returns 0 if the given user is not invested in the pool.
    * @param user Address of the user.
    * @return uint Balance of the user in USD.
    */
    function getUSDBalance(address user) external view returns (uint);

    /**
    * @notice Returns the number of pool tokens the user has.
    * @dev Returns 0 if the given user is not invested in the pool.
    * @param user Address of the user.
    * @return uint Number of pool tokens the user has.
    */
    function balanceOf(address user) external view returns (uint);

    /**
    * @notice Deposits the given USD amount into the pool.
    * @dev Call cUSD.approve() before calling this function.
    * @param amount Amount of USD to deposit into the pool.
    */
    function deposit(uint amount) external;

    /**
    * @notice Withdraws the given number of pool tokens from the user.
    * @param numberOfPoolTokens Number of pool tokens to withdraw.
    */
    function withdraw(uint numberOfPoolTokens) external;

    /**
    * @notice Withdraws the user's full investment.
    */
    function exit() external;

    /**
    * @notice Returns the pool's performance fee.
    */
    function getPerformanceFee() external view returns (uint);

    /**
    * @notice Returns the pool's USD value of the asset.
    * @param asset Address of the asset.
    * @param assetHandlerAddress Address of AssetHandler contract.
    * @return uint Pool's USD value of the asset.
    */
    function getAssetValue(address asset, address assetHandlerAddress) external view returns (uint);

    /**
    * @notice Returns the price of the pool's token in USD.
    */
    function tokenPrice() external view returns (uint);

    /**
    * @notice Returns the pool manager's available fees.
    */
    function availableManagerFee() external view returns (uint);

    /**
    * @notice Returns the total supply of LP tokens in the pool.
    */
    function totalSupply() external view returns (uint);
}