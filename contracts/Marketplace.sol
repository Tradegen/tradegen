pragma solidity >=0.5.0;

//libraries
import './libraries/SafeMath.sol';

import './Strategy.sol';
import './StrategyManager.sol';
import './UserManager.sol';

contract Marketplace {
    using SafeMath for uint256;

    struct PositionForSale {
        string strategyName;
        string strategySymbol;
        string sellerUsername;
        address strategyAddress;
        address sellerAddress;
        uint numberOfTokens;
        uint advertisedPrice;
        uint marketPrice;
    }

    mapping (address => PositionForSale[]) public userToMarketplaceListings; //stores the marketplace listings for a given user
    mapping (address => mapping (address => uint)) public userToNumberOfTokensForSale; //stores number of tokens for sale for each position a given user has

    /* ========== VIEWS ========== */

    function getUserPositionsForSale(address _user) public view returns (PositionForSale[] memory) {
        return userToMarketplaceListings[_user];
    }

    function getMarketplaceListing(address user, uint marketplaceListingIndex) public view marketplaceListingIndexWithinBounds(marketplaceListingIndex) returns (address, address, uint, uint) {
        PositionForSale memory marketplaceListing = userToMarketplaceListings[user][marketplaceListingIndex];

        return (marketplaceListing.strategyAddress, marketplaceListing.sellerAddress, marketplaceListing.advertisedPrice, marketplaceListing.numberOfTokens);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function listPositionForSale(address strategyAddress, uint price, uint numberOfTokens) external isValidStrategyAddress(strategyAddress) {
        require(price > 0, "Price cannot be 0");
        require(numberOfTokens > 0, "Price cannot be 0");

        uint userBalance = Strategy(strategyAddress).balanceOf[msg.sender];

        require(userBalance > 0, "No tokens in this strategy");
        require(userBalance - userToNumberOfTokensForSale[msg.sender][strategyAddress] >= numberOfTokens, "Not enough tokens in this strategy");

        string username = UserManager.getUser(msg.sender).username;
        (string strategyName, string strategySymbol, , , , , , , uint tokenPrice, ) = Strategy(strategyAddress)._getStrategyDetails();
        userToMarketplaceListings[msg.sender].push(PositionForSale(strategyName, strategySymbol, username, strategyAddress, msg.sender, numberOfTokens, price, tokenPrice));
        userToNumberOfTokensForSale[msg.sender][strategyAddress].add(numberOfTokens);

        emit ListedPositionForSale(msg.sender, strategyAddress, userToMarketplaceListings[msg.sender].length - 1, price, numberOfTokens, block.timestamp);
    }

    function editListing(uint marketplaceListingIndex, uint256 newPrice) external marketplaceListingIndexWithinBounds(msg.sender, marketplaceListingIndex) {
        require(newPrice > 0, "Price cannot be 0");

        userToMarketplaceListings[msg.sender][marketplaceListingsIndex].advertisedPrice = newPrice;

        emit UpdatedListing(msg.sender, userToMarketplaceListings[msg.sender][marketplaceListingsIndex].strategyAddress, marketplaceListingIndex, newPrice, block.timestamp);
    }

    function cancelListing(uint marketplaceListingIndex) external marketplaceListingIndexWithinBounds(msg.sender, marketplaceListingIndex) {
        _cancelListing(msg.sender, marketplaceListingIndex);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _cancelListing(address _user, uint marketplaceListingIndex) internal {
        uint numberOfTokens = userToMarketplaceListings[_user][marketplaceListingIndex].numberOfTokens;
        address strategyAddress = userToMarketplaceListings[_user][marketplaceListingIndex].strategyAddress;
        userToMarketplaceListings[_user][marketplaceListingIndex] = userToMarketplaceListings[_user][userToMarketplaceListings[_user].length - 1];

        delete userToMarketplaceListings[_user][userToMarketplaceListings[_user].length - 1];

        marketplaceListings[marketplaceListingIndex] = marketplaceListings[marketplaceListings.length - 1];

        userToNumberOfTokensForSale[_user][strategyAddress].sub(numberOfTokens);

        if (userToNumberOfTokensForSale[_user][strategyAddress] == 0)
        {
            delete userToNumberOfTokensForSale[_user][strategyAddress];
        }

        emit CancelledListing(_user, strategyAddress, marketplaceListingIndex, block.timestamp);
    }

    /* ========== MODIFIERS ========== */

    modifier marketplaceListingIndexWithinBounds(address user, uint marketplaceListingIndex) {
        require(marketplaceListingIndex < userToMarketplaceListings[user].length, "Marketplace listing index out of bounds");
        _;
    }

    /* ========== EVENTS ========== */

    event ListedPositionForSale(address user, address strategyAddress, uint marketplaceListingIndex, uint price, uint numberOfTokens, uint timestamp);
    event UpdatedListing(address user, address strategyAddress, uint marketplaceListingIndex, uint newPrice, uint timestamp);
    event CancelledListing(address user, address strategyAddress, uint marketplaceListingIndex, uint timestamp);
}