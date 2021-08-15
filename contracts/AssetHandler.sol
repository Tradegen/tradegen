pragma solidity >=0.5.0;

//Inheritance
import "./interfaces/IAssetHandler.sol";
import './Ownable.sol';

//Interfaces
import './interfaces/IPriceAggregator.sol';

contract AssetHandler is IAssetHandler, Ownable {

    mapping (address => uint) public assetTypes;
    mapping (uint => address) public assetTypeToPriceAggregator;
    mapping (uint => uint) public numberOfAvailableAssetsForType;
    mapping (uint => mapping (uint => address)) public availableAssetsForType;

    constructor() public Ownable() {}

    /* ========== VIEWS ========== */

    function getUSDPrice(address asset) public view override returns (uint) {
        require(asset != address(0), "AssetHandler: invalid asset address");
        require(assetTypes[asset] > 0, "AssetHandler: asset not supported");
        
        return IPriceAggregator(assetTypeToPriceAggregator[assetTypes[asset]]).getUSDPrice(asset);
    }

    function isValidAsset(address asset) public view override returns (bool) {
        require(asset != address(0), "AssetHandler: invalid asset address");

        return (assetTypes[asset] > 0);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    
}