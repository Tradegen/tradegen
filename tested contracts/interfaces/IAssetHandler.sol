// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IAssetHandler {
    /**
    * @dev Given the address of an asset, returns the asset's price in USD
    * @param asset Address of the asset
    * @return uint Price of the asset in USD
    */
    function getUSDPrice(address asset) external view returns (uint);

    /**
    * @dev Given the address of an asset, returns whether the asset is supported on Tradegen
    * @param asset Address of the asset
    * @return bool Whether the asset is supported
    */
    function isValidAsset(address asset) external view returns (bool);

    /**
    * @dev Given an asset type, returns the address of each supported asset for the type
    * @param assetType Type of asset
    * @return address[] Address of each supported asset for the type
    */
    function getAvailableAssetsForType(uint assetType) external view returns (address[] memory);

    /**
    * @dev Returns the address of the stable coin
    * @return address The stable coin address
    */
    function getStableCoinAddress() external view returns(address);

    /**
    * @dev Given the address of an asset, returns the asset's type
    * @param addressToCheck Address of the asset
    * @return uint Type of the asset
    */
    function getAssetType(address addressToCheck) external view returns (uint);

    /**
    * @dev Returns the pool's balance of the given asset
    * @param pool Address of the pool
    * @param asset Address of the asset
    * @return uint Pool's balance of the asset
    */
    function getBalance(address pool, address asset) external view returns (uint);

    /**
    * @dev Returns the asset's number of decimals
    * @param asset Address of the asset
    * @return uint Number of decimals
    */
    function getDecimals(address asset) external view returns (uint);

    /**
    * @dev Given the address of an asset, returns the address of the asset's verifier
    * @param asset Address of the asset
    * @return address Address of the asset's verifier
    */
    function getVerifier(address asset) external view returns (address);
}