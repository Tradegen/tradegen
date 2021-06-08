pragma solidity >=0.5.0;

import './libraries/SafeMath.sol';

import './StrategyManager.sol';
import './TradingBotRewards.sol';
import './Marketplace.sol';
import './Settings.sol';

import './interfaces/IStrategyToken.sol';
import './interfaces/IERC20.sol';

contract StrategyProxy is Marketplace, StrategyManager {
    using SafeMath for uint;

     struct StrategyDetails {
        string name;
        string strategySymbol;
        address developerAddress;
        address strategyAddress;
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

    function getStrategyDetails(address strategyAddress) public view returns(StrategyDetails memory) {
        (string memory name,
        string memory symbol,
        address developerAddress,
        uint publishedOnTimestamp,
        uint maxPoolSize,
        uint tokenPrice,
        uint circulatingSupply) = IStrategyToken(strategyAddress)._getStrategyDetails();

        return StrategyDetails(name,
                            symbol,
                            developerAddress,
                            strategyAddress,
                            publishedOnTimestamp,
                            maxPoolSize,
                            tokenPrice,
                            circulatingSupply);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function depositFundsIntoStrategy(address strategyAddress, uint amount) external isValidStrategyAddress(strategyAddress) noYieldToClaim(msg.sender, strategyAddress) botIsNotInATrade(strategyAddress) {
        address tradingBotAddress = IStrategyToken(strategyAddress).getTradingBotAddress();
        address developerAddress = IStrategyToken(strategyAddress).getDeveloperAddress();

        uint transactionFee = amount.mul(Settings(getSettingsAddress()).getTransactionFee()).div(1000);

        IERC20(getBaseTradegenAddress()).restrictedTransfer(msg.sender, tradingBotAddress, amount);
        IERC20(getBaseTradegenAddress()).restrictedTransfer(msg.sender, developerAddress, transactionFee);
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

    function withdrawFundsFromStrategy(address strategyAddress, uint amount) external noYieldToClaim(msg.sender, strategyAddress) botIsNotInATrade(strategyAddress) {
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

        address tradingBotAddress = IStrategyToken(strategyAddress).getTradingBotAddress();

        IERC20(getBaseTradegenAddress()).restrictedTransfer(tradingBotAddress, msg.sender, amount);
        IStrategyToken(strategyAddress).withdraw(msg.sender, amount);

        if (IStrategyToken(strategyAddress).getBalanceOf(msg.sender) == 0)
        {
            _removePosition(msg.sender, strategyAddress);
        }

        emit WithdrewFundsFromStrategy(msg.sender, strategyAddress, amount, block.timestamp);
    }

    function buyPosition(address user, uint marketplaceListingIndex) external {
        (uint advertisedPrice, uint numberOfTokens, address strategyAddress) = getMarketplaceListing(user, marketplaceListingIndex);

        address developerAddress = IStrategyToken(strategyAddress).getDeveloperAddress();

        uint amount = numberOfTokens.mul(advertisedPrice);
        uint transactionFee = amount.mul(Settings(getSettingsAddress()).getTransactionFee()).div(1000);
        
        IStrategyToken(strategyAddress).buyPosition(user, msg.sender, numberOfTokens);
        IERC20(getBaseTradegenAddress()).restrictedTransfer(msg.sender, user, amount);
        IERC20(getBaseTradegenAddress()).restrictedTransfer(msg.sender, developerAddress, transactionFee);

        _cancelListing(user, marketplaceListingIndex);

        emit BoughtPosition(msg.sender, strategyAddress, advertisedPrice, numberOfTokens, block.timestamp);
    }

    function _claim(address user, bool debtOrYield, uint amount) public onlyTradingBot(msg.sender) {
        //transfer profit from bot to user
        if (debtOrYield)
        {
            IERC20(getBaseTradegenAddress()).restrictedTransfer(msg.sender, user, amount);
        }
        //transfer loss from bot to user
        else
        {
            IERC20(getBaseTradegenAddress()).restrictedTransfer(user, msg.sender, amount);
        }
    }

    /* ========== MODIFIERS ========== */

    modifier noYieldToClaim(address user, address tradingBotAddress) {
        (, uint amount) = TradingBotRewards(getTradingBotRewardsAddress()).getUserAvailableYieldForBot(user, tradingBotAddress);
        require(amount == 0, "Need to claim yield first");
        _;
    }

    modifier botIsNotInATrade(address strategyAddress) {
        require(!Strategy(strategyAddress).checkIfBotIsInATrade(), "Cannot deposit or withdraw funds when bot is in a trade");
        _;
    }

    /* ========== EVENTS ========== */

    event DepositedFundsIntoStrategy(address user, address strategyAddress, uint amount, uint timestamp);
    event WithdrewFundsFromStrategy(address user, address strategyAddress, uint amount, uint timestamp);
    event BoughtPosition(address user, address strategyAddress, uint advertisedPrice, uint numberOfTokens, uint timestamp);
}