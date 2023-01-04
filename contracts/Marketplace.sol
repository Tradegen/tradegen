// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

// Libraries.
import "./openzeppelin-solidity/SafeMath.sol";
import "./openzeppelin-solidity/SafeERC20.sol";

// Inheritance.
import './interfaces/IMarketplace.sol';
import './Ownable.sol';

// Interfaces.
import './interfaces/IAddressResolver.sol';
import './interfaces/ISettings.sol';
import './interfaces/IAssetHandler.sol';
import './interfaces/ISellable.sol';

contract Marketplace is IMarketplace, Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IAddressResolver public immutable ADDRESS_RESOLVER;

    mapping (uint => MarketplaceListing) public marketplaceListings; // Starts at index 1; increases without bounds.
    uint public numberOfMarketplaceListings;
    mapping (address => mapping (address => uint)) public userToListingIndex; // Max 1 listing per user per asset.

    // Address of the asset's manager (used for sending manager's fee).
    // Set to asset's address if asset doesn't have manager (no manager fee in this case).
    // Set to address(0) if invalid asset.
    mapping (address => address) public assetManagers; 

    // Set of contracts that can add a new asset to marketplace.
    mapping (address => bool) public whitelistedContracts;

    constructor(IAddressResolver addressResolver) Ownable() {
        ADDRESS_RESOLVER = addressResolver;
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Given the address of a user and an asset, returns the index of the marketplace listing.
    * @dev Returns 0 if user doesn't have a listing in the given asset.
    * @param user Address of the user.
    * @param asset Address of the asset.
    * @return uint Index of the user's marketplace listing.
    */
    function getListingIndex(address user, address asset) external view override returns (uint) {
        require(user != address(0), "Marketplace: Invalid user address.");
        require(asset != address(0), "Marketplace: Invalid asset.");

        return userToListingIndex[asset][user];
    }

    /**
    * @notice Given the index of a marketplace listing, returns the listing's data.
    * @param index Index of the marketplace listing.
    * @return (address, address, uint, uint, uint) Asset for sale, address of the seller, asset's token class, number of tokens for sale, USD per token.
    */
    function getMarketplaceListing(uint index) external view override indexInRange(index) returns (address, address, uint, uint, uint) {
        MarketplaceListing memory listing = marketplaceListings[index];

        return (listing.asset, listing.seller, listing.tokenClass, listing.numberOfTokens, listing.price);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Purchases the specified number of tokens from the marketplace listing.
    * @param asset Address of the token for sale.
    * @param index Index of the marketplace listing in the asset's listings array.
    * @param numberOfTokens Number of tokens to purchase.
    */
    function purchase(address asset, uint index, uint numberOfTokens) external override isValidAsset(asset) {
        require(marketplaceListings[index].exists, "Marketplace: Listing doesn't exist.");
        require(numberOfTokens > 0 &&
                numberOfTokens <= marketplaceListings[index].numberOfTokens,
                "Marketplace: Quantity out of bounds.");
        require(msg.sender != marketplaceListings[index].seller, "Marketplace: Cannot buy your own position.");
        
        address settingsAddress = ADDRESS_RESOLVER.getContractAddress("Settings");
        uint protocolFee = ISettings(settingsAddress).getParameterValue("MarketplaceProtocolFee");
        uint managerFee = (assetManagers[asset] != asset) ? ISettings(settingsAddress).getParameterValue("MarketplaceAssetManagerFee") : 0;
        address stableCoinAddress = IAssetHandler(ADDRESS_RESOLVER.getContractAddress("AssetHandler")).getStableCoinAddress();

        uint amountOfUSD = marketplaceListings[index].price.mul(numberOfTokens);

        IERC20(stableCoinAddress).safeTransferFrom(msg.sender, address(this), amountOfUSD);
        
        // Transfer cUSD to seller and pay protocol fee.
        IERC20(stableCoinAddress).safeTransfer(marketplaceListings[index].seller, amountOfUSD.mul(10000 - protocolFee - managerFee).div(10000));
        IERC20(stableCoinAddress).safeTransfer(ADDRESS_RESOLVER.getContractAddress("Treasury"), amountOfUSD.mul(protocolFee).div(10000));

        // Pay manager fee if asset has manager.
        if (managerFee > 0)
        {
            IERC20(stableCoinAddress).safeTransfer(assetManagers[asset], amountOfUSD.mul(managerFee).div(10000));
        }

        // Transfer tokens from seller to buyer.
        require(ISellable(asset).transfer(marketplaceListings[index].seller, msg.sender, marketplaceListings[index].tokenClass, numberOfTokens), "Marketplace: Token transfer failed.");

        // Update marketplace listing.
        if (numberOfTokens == marketplaceListings[index].numberOfTokens)
        {
            _removeListing(marketplaceListings[index].seller, asset, index);
        }
        else
        {
            marketplaceListings[index].numberOfTokens = marketplaceListings[index].numberOfTokens.sub(numberOfTokens);
        }

        emit Purchased(msg.sender, asset, index, numberOfTokens, marketplaceListings[index].price, block.timestamp);
    }

    /**
    * @notice Creates a new marketplace listing with the given price and quantity.
    * @param asset Address of the token for sale.
    * @param tokenClass The class of the asset's token.
    * @param numberOfTokens Number of tokens to sell.
    * @param price USD per token.
    */
    function createListing(address asset, uint tokenClass, uint numberOfTokens, uint price) external override isValidAsset(asset) {
        require(userToListingIndex[asset][msg.sender] == 0, "Marketplace: Already have a marketplace listing for this asset.");
        require(price > 0, "Marketplace: Price must be greater than 0.");
        require(tokenClass > 0 && tokenClass < 5, "Marketplace: Token class must be between 1 and 4.");
        require(numberOfTokens > 0 && numberOfTokens <= ISellable(asset).balanceOf(msg.sender, tokenClass), "Marketplace: Quantity out of bounds.");

        numberOfMarketplaceListings = numberOfMarketplaceListings.add(1);
        userToListingIndex[asset][msg.sender] = numberOfMarketplaceListings;
        marketplaceListings[numberOfMarketplaceListings] = MarketplaceListing(asset, msg.sender, true, tokenClass, numberOfTokens, price);

        emit CreatedListing(msg.sender, asset, numberOfMarketplaceListings, tokenClass, numberOfTokens, price, block.timestamp);
    }

    /**
    * @notice Removes the marketplace listing at the given index.
    * @param asset Address of the token for sale.
    * @param index Index of the marketplace listing in the asset's listings array.
    */
    function removeListing(address asset, uint index) external override isValidAsset(asset) indexInRange(index) onlySeller(asset, index) {
        _removeListing(msg.sender, asset, index);

        emit RemovedListing(msg.sender, asset, index, block.timestamp);
    }

    /**
    * @notice Updates the price of the given marketplace listing.
    * @param asset Address of the token for sale.
    * @param index Index of the marketplace listing in the asset's listings array.
    * @param newPrice USD per token.
    */
    function updatePrice(address asset, uint index, uint newPrice) external override isValidAsset(asset) indexInRange(index) onlySeller(asset, index) {
        require(newPrice > 0, "Marketplace: New price must be greater than 0.");

        marketplaceListings[index].price = newPrice;

        emit UpdatedPrice(msg.sender, asset, index, newPrice, block.timestamp);
    }

    /**
    * @notice Updates the number of tokens for sale of the given marketplace listing.
    * @param asset Address of the token for sale.
    * @param index Index of the marketplace listing in the asset's listings array.
    * @param newQuantity Number of tokens to sell.
    */
    function updateQuantity(address asset, uint index, uint newQuantity) external override isValidAsset(asset) indexInRange(index) onlySeller(asset, index) {
        require(newQuantity > 0 &&
                newQuantity <= ISellable(asset).balanceOf(msg.sender, marketplaceListings[index].tokenClass),
                "Marketplace: Quantity out of bounds.");

        marketplaceListings[index].numberOfTokens = newQuantity;

        emit UpdatedQuantity(msg.sender, asset, index, newQuantity, block.timestamp);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @notice Adds a new sellable asset to the marketplace.
    * @dev Meant to be called by whitelisted contract.
    * @dev Set 'manager' to asset address if asset doesn't have manager.
    * @param asset Address of the asset to add.
    * @param manager Address of the asset's manager (or asset's address if asset doesn't have manager).
    */
    function addAsset(address asset, address manager) external override onlyWhitelistedContracts {
        require(asset != address(0), "Marketplace: Invalid asset address.");
        require(manager != address(0), "Marketplace: Invalid manager address.");
        require(assetManagers[asset] == address(0), "Marketplace: Already added this asset.");

        assetManagers[asset] = manager;

        emit AddedAsset(asset, block.timestamp);
    }

    /**
    * @notice Adds a new whitelisted contract.
    * @dev Meant to be called by Marketplace contract deployer.
    * @param contractAddress Address of contract to add.
    */
    function addWhitelistedContract(address contractAddress) external onlyOwner {
        require(contractAddress != address(0), "Marketplace: Invalid contract address.");
        require(!whitelistedContracts[contractAddress], "Marketplace: Contract already added.");

        whitelistedContracts[contractAddress] = true;

        emit AddedWhitelistedContract(contractAddress, block.timestamp);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
    * @notice Sets the marketplace listing's 'exists' variable to false and resets quantity.
    * @param user Address of the user.
    * @param asset Address of the asset.
    * @param index Index of the marketplace listing in the asset's listings array.
    */
    function _removeListing(address user, address asset, uint index) internal {
        marketplaceListings[index].exists = false;
        marketplaceListings[index].numberOfTokens = 0;

        userToListingIndex[asset][user] = 0;
    }

    /* ========== MODIFIERS ========== */

    modifier indexInRange(uint index) {
        require(index > 0 &&
                index <= numberOfMarketplaceListings,
                "Marketplace: Index out of range.");
        _;
    }

    modifier onlySeller(address asset, uint index) {
        require(index == userToListingIndex[asset][msg.sender],
                "Marketplace: Only the seller can call this function.");
        _;
    }

    modifier onlyWhitelistedContracts() {
        require(whitelistedContracts[msg.sender],
                "Marketplace: Only whitelisted contract can call this function.");
        _;
    }

    modifier isValidAsset(address asset) {
        require(asset != address(0) &&
                assetManagers[asset] != address(0), 
                "Marketplace: Invalid asset.");
        _;
    }
}