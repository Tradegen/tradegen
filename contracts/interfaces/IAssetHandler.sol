pragma solidity >=0.5.0;

interface IAssetHandler {
    function getUSDPrice(address asset) external view returns (uint);

    function isValidAsset(address asset) external view returns (bool);
}