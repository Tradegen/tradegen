pragma solidity >=0.5.0;

interface IAssetHandler {
    function getUSDPrice(address asset) external view returns (uint);

    function isValidAsset(address asset) external view returns (bool);

    function getAvailableAssetsForType(uint assetType) external view returns (address[] memory);

    /**
    * @dev Returns the address of the stable coin
    * @return address The stable coin address
    */
    function getStableCoinAddress() external view returns(address);
}