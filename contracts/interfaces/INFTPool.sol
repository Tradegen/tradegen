// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface INFTPool {
    /**
    * @notice Returns the currency address and balance of each position the pool has, as well as the cumulative value.
    * @return (address[], uint[], uint) Currency address and balance of each position the pool has, and the cumulative value of positions.
    */
    function getPositionsAndTotal() external view returns (address[] memory, uint[] memory, uint);

    /**
    * @notice Returns the amount of cUSD the pool has to invest.
    * @return uint Amount of cUSD in the pool.
    */
    function getAvailableFunds() external view returns (uint);

    /**
    * @notice Returns the value of the pool in USD.
    * @return uint Value of the pool in USD.
    */
    function getPoolValue() external view returns (uint);

    /**
    * @notice Returns the balance of the user in USD.
    * @return uint Balance of the user in USD.
    */
    function getUSDBalance(address user) external view returns (uint);

    /**
    * @notice Purchases the given amount of pool tokens.
    * @dev Call cUSD.approve() before calling this function.
    * @param numberOfPoolTokens Number of pool tokens to purchase.
    */
    function deposit(uint numberOfPoolTokens) external;

    /**
    * @notice Withdraws the user's full investment.
    * @param numberOfPoolTokens Number of pool tokens to withdraw.
    * @param tokenClass Token class to withdraw from.
    */
    function withdraw(uint numberOfPoolTokens, uint tokenClass) external;

    /**
    * @notice Withdraws the user's full investment.
    */
    function exit() external;

    /**
    * @notice Returns the pool's USD value of the asset.
    * @param asset Address of the asset.
    * @param assetHandlerAddress Address of AssetHandler contract.
    * @return uint Pool's USD value of the asset.
    */
    function getAssetValue(address asset, address assetHandlerAddress) external view returns (uint);

    /**
    * @notice Returns the supply price of the pool's token.
    * @return USD supply price of the pool's token.
    */
    function tokenPrice() external view returns (uint);

    /**
    * @notice Returns the total supply of pool tokens.
    * @return uint Total supply of pool tokens.
    */
    function totalSupply() external view returns (uint);
}