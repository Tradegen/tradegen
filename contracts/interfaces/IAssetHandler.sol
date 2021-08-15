pragma solidity >=0.5.0;

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
}