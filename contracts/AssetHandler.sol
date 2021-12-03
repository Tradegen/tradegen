// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//Inheritance
import "./interfaces/IAssetHandler.sol";
import './Ownable.sol';

//Interfaces
import './interfaces/IPriceAggregator.sol';
import './interfaces/IAddressResolver.sol';
import './interfaces/IAssetVerifier.sol';

//Libraries
import "./openzeppelin-solidity/SafeMath.sol";

contract AssetHandler is IAssetHandler, Ownable {
    using SafeMath for uint;

    IAddressResolver public ADDRESS_RESOLVER;

    address public stableCoinAddress;
    mapping (address => uint) public assetTypes;
    mapping (uint => address) public assetTypeToPriceAggregator;
    mapping (uint => uint) public numberOfAvailableAssetsForType;
    mapping (uint => mapping (uint => address)) public availableAssetsForType;

    constructor(IAddressResolver addressResolver) Ownable() {
        ADDRESS_RESOLVER = addressResolver;
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Given the address of an asset, returns the asset's price in USD
    * @param asset Address of the asset
    * @return uint Price of the asset in USD
    */
    function getUSDPrice(address asset) external view override isValidAddress(asset) returns (uint) {
        require(assetTypes[asset] > 0, "AssetHandler: asset not supported");
        
        return IPriceAggregator(assetTypeToPriceAggregator[assetTypes[asset]]).getUSDPrice(asset);
    }

    /**
    * @dev Given the address of an asset, returns whether the asset is supported on Tradegen
    * @param asset Address of the asset
    * @return bool Whether the asset is supported
    */
    function isValidAsset(address asset) external view override isValidAddress(asset) returns (bool) {
        return (assetTypes[asset] > 0 || asset == stableCoinAddress);
    }

    /**
    * @dev Given an asset type, returns the address of each supported asset for the type
    * @param assetType Type of asset
    * @return address[] Address of each supported asset for the type
    */
    function getAvailableAssetsForType(uint assetType) external view override returns (address[] memory) {
        require(assetType > 0, "AssetHandler: assetType must be greater than 0");

        uint numberOfAssets = numberOfAvailableAssetsForType[assetType];
        address[] memory assets = new address[](numberOfAssets);

        for(uint i = 0; i < numberOfAssets; i++)
        {
            assets[i] = availableAssetsForType[assetType][i];
        }

        return assets;
    }

    /**
    * @dev Returns the address of the stable coin
    * @return address The stable coin address
    */
    function getStableCoinAddress() external view override returns(address) {
        return stableCoinAddress;
    }

    /**
    * @dev Given the address of an asset, returns the asset's type
    * @param addressToCheck Address of the asset
    * @return uint Type of the asset
    */
    function getAssetType(address addressToCheck) external view override isValidAddress(addressToCheck) returns (uint) {
        return assetTypes[addressToCheck];
    }

    /**
    * @dev Returns the pool's balance of the given asset
    * @param pool Address of the pool
    * @param asset Address of the asset
    * @return uint Pool's balance of the asset
    */
    function getBalance(address pool, address asset) external view override isValidAddress(pool) isValidAddress(asset) returns (uint) {
        address verifier = getVerifier(asset);

        return IAssetVerifier(verifier).getBalance(pool, asset);
    }

    /**
    * @dev Returns the asset's number of decimals
    * @param asset Address of the asset
    * @return uint Number of decimals
    */
    function getDecimals(address asset) external view override isValidAddress(asset) returns (uint) {
        uint assetType = assetTypes[asset];
        address verifier = ADDRESS_RESOLVER.assetVerifiers(assetType);

        return IAssetVerifier(verifier).getDecimals(asset);
    }

    /**
    * @dev Given the address of an asset, returns the address of the asset's verifier
    * @param asset Address of the asset
    * @return address Address of the asset's verifier
    */
    function getVerifier(address asset) public view override isValidAddress(asset) returns (address) {
        uint assetType = assetTypes[asset];

        return ADDRESS_RESOLVER.assetVerifiers(assetType);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @dev Sets the address of the stable coin
    * @param _stableCoinAddress The address of the stable coin
    */
    function setStableCoinAddress(address _stableCoinAddress) external onlyOwner isValidAddress(_stableCoinAddress) {
        address oldAddress = stableCoinAddress;
        stableCoinAddress = _stableCoinAddress;
        assetTypes[_stableCoinAddress] = 1;

        emit UpdatedStableCoinAddress(oldAddress, _stableCoinAddress, block.timestamp);
    }

    /**
    * @dev Adds a new tradable currency to the platform
    * @param assetType Type of the asset
    * @param currencyKey The address of the asset to add
    */
    function addCurrencyKey(uint assetType, address currencyKey) external onlyOwner isValidAddress(currencyKey) {
        require(assetType > 0, "AssetHandler: assetType must be greater than 0");
        require(currencyKey != stableCoinAddress, "AssetHandler: Cannot equal stablecoin address");
        require(assetTypes[currencyKey] == 0, "AssetHandler: Asset already exists");

        assetTypes[currencyKey] = assetType;
        availableAssetsForType[assetType][numberOfAvailableAssetsForType[assetType]] = currencyKey;
        numberOfAvailableAssetsForType[assetType] = numberOfAvailableAssetsForType[assetType].add(1);

        emit AddedAsset(assetType, currencyKey, block.timestamp);
    }

    /**
    * @dev Removes support for a currency
    * @param assetType Type of the asset
    * @param currencyKey The address of the asset to remove
    */
    function removeCurrencyKey(uint assetType, address currencyKey) external onlyOwner isValidAddress(currencyKey) {
        require(assetType > 0, "AssetHandler: assetType must be greater than 0");
        require(currencyKey != stableCoinAddress, "AssetHandler: Cannot equal stablecoin address");
        require(assetTypes[currencyKey] > 0, "AssetHandler: Asset not found");

        uint numberOfAssets = numberOfAvailableAssetsForType[assetType];
        uint index;
        for (index = 1; index <= numberOfAssets; index++)
        {
            if (availableAssetsForType[assetType][index] == currencyKey) break;
        }

        require(index <= numberOfAssets, "AssetHandler: Index out of bounds");

        //Move last element to the index of currency being removed
        if (index < numberOfAssets)
        {
            availableAssetsForType[assetType][index] = availableAssetsForType[assetType][numberOfAssets];
        }

        delete availableAssetsForType[assetType][numberOfAssets];
        delete assetTypes[currencyKey];
        numberOfAvailableAssetsForType[assetType] = numberOfAvailableAssetsForType[assetType].sub(1);

        emit AddedAsset(assetType, currencyKey, block.timestamp);
    }

    /**
    * @dev Adds a new asset type
    * @param assetType Type of the asset
    * @param priceAggregator Address of the asset's price aggregator
    */
    function addAssetType(uint assetType, address priceAggregator) external onlyOwner isValidAddress(priceAggregator) {
        require(assetType > 0, "AssetHandler: assetType must be greater than 0");
        require(assetTypeToPriceAggregator[assetType] == address(0), "AssetHandler: asset type already exists");

        assetTypeToPriceAggregator[assetType] = priceAggregator;

        emit AddedAssetType(assetType, priceAggregator, block.timestamp);
    }

    /* ========== MODIFIERS ========== */

    modifier isValidAddress(address addressToCheck) {
        require(addressToCheck != address(0), "AssetHandler: Address is not valid");
        _;
    }

    /* ========== EVENTS ========== */

    event AddedAsset(uint assetType, address currencyKey, uint timestamp);
    event UpdatedStableCoinAddress(address oldAddress, address stableCurrencyAddress, uint timestamp);
    event AddedAssetType(uint assetType, address priceAggregator, uint timestamp); 
}