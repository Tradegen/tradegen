pragma solidity >=0.5.0;

import './StrategyManager.sol';
import './Marketplace.sol';
import './TradegenERC20.sol';
import './AddressResolver.sol';

import './interfaces/IStrategyToken.sol';
import './interfaces/IERC20.sol';

contract StrategyProxy is StrategyManager, TradegenERC20, Marketplace {

     struct StrategyDetails {
        string name;
        string strategySymbol;
        string description;
        string underlyingAssetSymbol;
        address developerAddress;
        address strategyAddress;
        bool direction;
        uint publishedOnTimestamp;
        uint maxPoolSize;
        uint tokenPrice;
        uint circulatingSupply;
    }

    struct PositionDetails {
        string name;
        string strategySymbol;
        address strategyAddress;
        uint balance;
        uint circulatingSupply;
        uint maxPoolSize;
    }

    /* ========== VIEWS ========== */

    function getUserPublishedStrategies() external view returns(StrategyDetails[] memory) {
        address[] memory userPublishedStrategiesAddresses = _getUserPublishedStrategies(msg.sender);
        StrategyDetails[] memory userPublishedStrategiesWithDetails = new StrategyDetails[](userPublishedStrategiesAddresses.length);

        for (uint i = 0; i < userPublishedStrategiesAddresses.length; i++)
        {
            userPublishedStrategiesWithDetails[i] = getStrategyDetails(userPublishedStrategiesAddresses[i]);
        }

        return userPublishedStrategiesWithDetails;
    }

    function getUserPositions() external view returns(PositionDetails[] memory) {
        address[] memory userPositionAddresses = _getUserPositions(msg.sender);
        PositionDetails[] memory userPositionsWithDetails = new PositionDetails[](userPositionAddresses.length);

        for (uint i = 0; i < userPositionAddresses.length; i++)
        {
            (string memory name,
            string memory symbol,
            uint balance,
            uint circulatingSupply,
            uint maxPoolSize) = IStrategyToken(userPositionAddresses[i])._getPositionDetails(msg.sender);

            userPositionsWithDetails[i] = PositionDetails(name,
                                                        symbol,
                                                        userPositionAddresses[i],
                                                        balance,
                                                        circulatingSupply,
                                                        maxPoolSize);
        }

        return userPositionsWithDetails;
    }

    function getStrategyDetails(address strategyAddress) public view returns(StrategyDetails memory) {
        (string memory name,
        string memory symbol,
        string memory description,
        string memory underlyingAssetSymbol,
        address developerAddress,
        bool direction,
        uint publishedOnTimestamp,
        uint maxPoolSize,
        uint tokenPrice,
        uint circulatingSupply) = IStrategyToken(strategyAddress)._getStrategyDetails();

        return StrategyDetails(name,
                            symbol,
                            description,
                            underlyingAssetSymbol,
                            developerAddress,
                            strategyAddress,
                            direction,
                            publishedOnTimestamp,
                            maxPoolSize,
                            tokenPrice,
                            circulatingSupply);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function depositFundsIntoStrategy(address strategyAddress, uint amount) external isValidStrategyAddress(strategyAddress) {
        address tradingBotAddress = Strategy(strategyAddress).getTradingBotAddress();

        TradegenERC20._transfer(msg.sender, tradingBotAddress, amount);
        IStrategyToken(strategyAddress).deposit(msg.sender, amount);

        //add to user's positions if user is investing in this strategy for the first time
        uint strategyIndex = addressToIndex[strategyAddress] - 1;
        bool found = false;
        uint[] memory userPositionIndexes = userToPositions[msg.sender];
        for (uint i = 0; i < userPositionIndexes.length; i++)
        {
            if (userPositionIndexes[i] == strategyIndex)
            {
                found = true;
                break;
            }
        }

        if (!found)
        {
            _addPosition(msg.sender, strategyAddress);
        }

        emit DepositedFundsIntoStrategy(msg.sender, strategyAddress, amount, block.timestamp);
    }

    function withdrawFundsFromStrategy(address strategyAddress, uint amount) external {
        //check if user has position
        uint strategyIndex = addressToIndex[strategyAddress] - 1;
        bool found = false;
        uint[] memory userPositionIndexes = userToPositions[msg.sender];
        for (uint i = 0; i < userPositionIndexes.length; i++)
        {
            if (userPositionIndexes[i] == strategyIndex)
            {
                found = true;
                break;
            }
        }

        require(found, "No position in this strategy");

        IERC20(getBaseTradegenAddress())._transfer(Strategy(strategyAddress).getTradingBotAddress(), msg.sender, amount);
        IStrategyToken(strategyAddress).withdraw(msg.sender, amount);

        if (IStrategyToken(strategyAddress).getBalanceOf(msg.sender) == 0)
        {
            _removePosition(msg.sender, strategyAddress);
        }

        emit WithdrewFundsFromStrategy(msg.sender, strategyAddress, amount, block.timestamp);
    }

    function buyPosition(uint marketplaceListingIndex) external {
        (address strategyAddress, address sellerAddress, uint advertisedPrice, uint numberOfTokens) = getMarketplaceListing(marketplaceListingIndex);
        
        IStrategyToken(strategyAddress).buyPosition(sellerAddress, msg.sender, numberOfTokens);
        IERC20(getBaseTradegenAddress())._transfer(msg.sender, sellerAddress, numberOfTokens.mul(advertisedPrice));

        _cancelListing(msg.sender, marketplaceListingIndex);

        emit BoughtPosition(msg.sender, strategyAddress, advertisedPrice, numberOfTokens, block.timestamp);
    }

    /* ========== EVENTS ========== */

    event DepositedFundsIntoStrategy(address user, address strategyAddress, uint amount, uint timestamp);
    event WithdrewFundsFromStrategy(address user, address strategyAddress, uint amount, uint timestamp);
    event BoughtPosition(address user, address strategyAddress, uint advertisedPrice, uint numberOfTokens, uint timestamp);
}