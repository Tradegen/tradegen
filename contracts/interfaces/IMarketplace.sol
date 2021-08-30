// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;

interface IMarketplace {

    struct MarketplaceListing {
        address asset;
        address seller;
        uint tokenClass;
        uint numberOfTokens;
        uint price;
    }

    /**
    * @dev Given the address of a user and an asset, returns the index of the marketplace listing
    * @notice Returns 0 if user doesn't have a listing in the given asset
    * @param user Address of the user
    * @param asset Address of the asset
    * @return uint Index of the user's marketplace listing
    */
    function getListingIndex(address user, address asset) external view returns (uint);

    /**
    * @dev Given the index of a marketplace listing, returns the listing's data
    * @param index Index of the marketplace listing
    * @return (address, address, uint, uint, uint) Asset for sale, address of the seller, asset's token class, number of tokens for sale, USD per token
    */
    function getMarketplaceListing(uint index) external view returns (address, address, uint, uint, uint);

    /**
    * @dev Purchases the specified number of tokens from the marketplace listing
    * @param asset Address of the token for sale
    * @param index Index of the marketplace listing
    * @param numberOfTokens Number of tokens to purchase
    */
    function purchase(address asset, uint index, uint numberOfTokens) external;

    /**
    * @dev Creates a new marketplace listing with the given price and quantity
    * @param asset Address of the token for sale
    * @param tokenClass The class of the asset's token
    * @param numberOfTokens Number of tokens to sell
    * @param price USD per token
    */
    function createListing(address asset, uint tokenClass, uint numberOfTokens, uint price) external;

    /**
    * @dev Removes the marketplace listing at the given index
    * @param asset Address of the token for sale
    * @param index Index of the marketplace listing
    */
    function removeListing(address asset, uint index) external;

    /**
    * @dev Updates the price of the given marketplace listing
    * @param asset Address of the token for sale
    * @param index Index of the marketplace listing
    * @param newPrice USD per token
    */
    function updatePrice(address asset, uint index, uint newPrice) external;

    /**
    * @dev Updates the number of tokens for sale of the given marketplace listing
    * @param asset Address of the token for sale
    * @param index Index of the marketplace listing
    * @param newQuantity Number of tokens to sell
    */
    function updateQuantity(address asset, uint index, uint newQuantity) external;

    /**
    * @dev Adds a new sellable asset to the marketplace
    * @notice Meant to be called by whitelisted contract
    * @notice Set 'manager' to asset address if asset doesn't have manager
    * @param asset Address of the asset to add
    * @param manager Address of the asset's manager (or asset's address if asset doesn't have manager)
    */
    function addAsset(address asset, address manager) external;

    /* ========== EVENTS ========== */

    event CreatedListing(address indexed seller, address indexed asset, uint tokenClass, uint numberOfTokens, uint price, uint timestamp);
    event RemovedListing(address indexed seller, address indexed asset, uint timestamp);
    event UpdatedPrice(address indexed seller, address indexed asset, uint marketplaceListing, uint newPrice, uint timestamp);
    event UpdatedQuantity(address indexed seller, address indexed asset, uint marketplaceListing, uint newQuantity, uint timestamp);
    event Purchased(address indexed buyer, address indexed asset, uint marketplaceListing, uint numberOfTokens, uint timestamp);
    event AddedAsset(address asset, uint timestamp);
    event AddedWhitelistedContract(address contractAddress, uint timestamp);
}