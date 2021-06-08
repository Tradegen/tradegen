pragma solidity >=0.5.0;

//libraries
import './libraries/SafeMath.sol';

import './interfaces/IStrategyToken.sol';

import './UserManager.sol';
import './AddressResolver.sol';

contract Marketplace is AddressResolver {
    using SafeMath for uint;

    struct PositionForSale {
        uint88 numberOfTokens;
        uint168 advertisedPrice;
        address strategyAddress;
    }

    mapping (address => PositionForSale[]) public userToMarketplaceListings; //stores the marketplace listings for a given user
    mapping (address => mapping (address => uint)) public userToNumberOfTokensForSale; //stores number of tokens for sale for each position a given user has

    /* ========== VIEWS ========== */

    function getUserPositionsForSale(address _user) public view returns (PositionForSale[] memory) {
        return userToMarketplaceListings[_user];
    }

    function getMarketplaceListing(address user, uint marketplaceListingIndex) public view marketplaceListingIndexWithinBounds(user, marketplaceListingIndex) returns (uint, uint, address) {
        PositionForSale memory marketplaceListing = userToMarketplaceListings[user][marketplaceListingIndex];

        return (uint256(marketplaceListing.advertisedPrice), uint256(marketplaceListing.numberOfTokens), marketplaceListing.strategyAddress);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function listPositionForSale(address strategyAddress, uint price, uint numberOfTokens) external isValidStrategyAddress(strategyAddress) {
        require(price > 0, "Price cannot be 0");
        require(numberOfTokens > 0, "Price cannot be 0");

        uint userBalance = IStrategyToken(strategyAddress).getBalanceOf(msg.sender);

        require(userBalance > 0, "No tokens in this strategy");
        require(userBalance - userToNumberOfTokensForSale[msg.sender][strategyAddress] >= numberOfTokens, "Not enough tokens in this strategy");

        userToMarketplaceListings[msg.sender].push(PositionForSale(uint88(numberOfTokens), uint168(price), strategyAddress));
        userToNumberOfTokensForSale[msg.sender][strategyAddress] = uint256(userToNumberOfTokensForSale[msg.sender][strategyAddress]).add(numberOfTokens);

        emit ListedPositionForSale(msg.sender, strategyAddress, userToMarketplaceListings[msg.sender].length - 1, price, numberOfTokens, block.timestamp);
    }

    function editListing(uint marketplaceListingIndex, uint newPrice) external marketplaceListingIndexWithinBounds(msg.sender, marketplaceListingIndex) {
        require(newPrice > 0, "Price cannot be 0");

        userToMarketplaceListings[msg.sender][marketplaceListingIndex].advertisedPrice = uint168(newPrice);

        emit UpdatedListing(msg.sender, userToMarketplaceListings[msg.sender][marketplaceListingIndex].strategyAddress, marketplaceListingIndex, newPrice, block.timestamp);
    }

    function cancelListing(uint marketplaceListingIndex) external {
        _cancelListing(msg.sender, marketplaceListingIndex);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _cancelListing(address _user, uint marketplaceListingIndex) internal marketplaceListingIndexWithinBounds(_user, marketplaceListingIndex) {
        uint numberOfTokens = userToMarketplaceListings[_user][marketplaceListingIndex].numberOfTokens;
        address strategyAddress = userToMarketplaceListings[_user][marketplaceListingIndex].strategyAddress;
        userToMarketplaceListings[_user][marketplaceListingIndex] = userToMarketplaceListings[_user][userToMarketplaceListings[_user].length - 1];

        userToMarketplaceListings[_user].pop();
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

    event ListedPositionForSale(address indexed user, address strategyAddress, uint marketplaceListingIndex, uint price, uint numberOfTokens, uint timestamp);
    event UpdatedListing(address indexed user, address strategyAddress, uint marketplaceListingIndex, uint newPrice, uint timestamp);
    event CancelledListing(address indexed user, address strategyAddress, uint marketplaceListingIndex, uint timestamp);
}