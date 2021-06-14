pragma solidity >=0.5.0;

//Libraries
import './libraries/SafeMath.sol';

import './StrategyManager.sol';
import './Marketplace.sol';

//Inheritance
import './interfaces/IStrategyToken.sol';
import './interfaces/IERC20.sol';
import './interfaces/IAddressResolver.sol';
import './interfaces/ITradingBotRewards.sol';
import './interfaces/ISettings.sol';

contract StrategyProxy is Marketplace, StrategyManager {
    using SafeMath for uint;

    ITradingBotRewards public immutable TRADING_BOT_REWARDS;
    IERC20 public immutable STABLE_COIN;
    ISettings public immutable SETTINGS;

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

    constructor(IAddressResolver addressResolver) public StrategyManager(addressResolver) Marketplace(addressResolver) {
        TRADING_BOT_REWARDS = ITradingBotRewards(addressResolver.getContractAddress("TradingBotRewards"));
        STABLE_COIN = IERC20(ISettings(addressResolver.getContractAddress("Settings")).getStableCoinAddress());
        SETTINGS = ISettings(addressResolver.getContractAddress("Settings"));
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Given the address of a strategy, returns the details for that strategy
    * @param strategyAddress Address of the strategy
    * @return StrategyDetails The name, token symbol, developer, timestamp, max pool size, toke price, and circulating supply of the strategy
    */
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

    /**
    * @dev Deposits the given cUSD amount into the strategy and mints LP tokens for the user
    * @param strategyAddress Address of the strategy
    * @param amount Amount of cUSD to deposit
    */
    function depositFundsIntoStrategy(address strategyAddress, uint amount) external isValidStrategyAddress(strategyAddress) noYieldToClaim(msg.sender, strategyAddress) botIsNotInATrade(strategyAddress) {
        address tradingBotAddress = IStrategyToken(strategyAddress).getTradingBotAddress();
        address developerAddress = IStrategyToken(strategyAddress).getDeveloperAddress();

        uint transactionFee = amount.mul(SETTINGS.getParameterValue("TransactionFee")).div(1000);

        //Deposits cUSD into trading bot and sends transaction fee to strategy's developer; call approve() on frontend before sending transaction
        STABLE_COIN.transferFrom(msg.sender, tradingBotAddress, amount);
        STABLE_COIN.transferFrom(msg.sender, developerAddress, transactionFee);

        //Mint LP tokens for the user
        IStrategyToken(strategyAddress).deposit(msg.sender, amount);

        //Add to user's positions if user is investing in this strategy for the first time
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

    /**
    * @dev Withdraws the given cUSD amount from the strategy and burns LP tokens for the user
    * @param strategyAddress Address of the strategy
    * @param amount Amount of cUSD to withdraw
    */
    function withdrawFundsFromStrategy(address strategyAddress, uint amount) external noYieldToClaim(msg.sender, strategyAddress) botIsNotInATrade(strategyAddress) isValidStrategyAddress(strategyAddress) {
        require(IStrategyToken(strategyAddress).getBalanceOf(msg.sender) >= amount, "Not enough LP tokens in strategy");
        
        //Check if user has position
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

        STABLE_COIN.transferFrom(tradingBotAddress, msg.sender, amount);

        //Burn LP tokens from the user
        IStrategyToken(strategyAddress).withdraw(msg.sender, amount);

        if (IStrategyToken(strategyAddress).getBalanceOf(msg.sender) == 0)
        {
            _removePosition(msg.sender, strategyAddress);
        }

        emit WithdrewFundsFromStrategy(msg.sender, strategyAddress, amount, block.timestamp);
    }

    /**
    * @dev Buys the specified marketplace listing from the seller
    * @param user Address of the seller
    * @param marketplaceListingIndex Index in the user's array of marketplace listings
    */
    function buyPosition(address user, uint marketplaceListingIndex) external {
        (uint advertisedPrice, uint numberOfTokens, address strategyAddress) = getMarketplaceListing(user, marketplaceListingIndex);

        address developerAddress = IStrategyToken(strategyAddress).getDeveloperAddress();

        uint amount = numberOfTokens.mul(advertisedPrice);
        uint transactionFee = amount.mul(SETTINGS.getParameterValue("TransactionFee")).div(1000);
        
        IStrategyToken(strategyAddress).buyPosition(user, msg.sender, numberOfTokens);

        //Transfers cUSD from buyer to seller and sends transaction fee to strategy's developer; call approve() on frontend before sending transaction
        STABLE_COIN.transferFrom(msg.sender, user, amount);
        STABLE_COIN.transferFrom(msg.sender, developerAddress, transactionFee);

        _cancelListing(user, marketplaceListingIndex);

        emit BoughtPosition(msg.sender, strategyAddress, advertisedPrice, numberOfTokens, block.timestamp);
    }

    /**
    * @dev Claims the available debt or yield on behalf of the user
    * @param user Address of the user
    * @param debtOrYield Whether the amount being claimed represents debt or yield
    * @param amount Amount of debt or yield to claim
    */
    function _claim(address user, bool debtOrYield, uint amount) public onlyTradingBot {
        //transfer profit from bot to user
        if (debtOrYield)
        {
            STABLE_COIN.transferFrom(msg.sender, user, amount);
        }
        //transfer loss from bot to user
        else
        {
            STABLE_COIN.transferFrom(user, msg.sender, amount);
        }
    }

    /* ========== MODIFIERS ========== */

    modifier noYieldToClaim(address user, address tradingBotAddress) {
        (, uint amount) = TRADING_BOT_REWARDS.getUserAvailableYieldForBot(user, tradingBotAddress);
        require(amount == 0, "Need to claim yield first");
        _;
    }

    modifier botIsNotInATrade(address strategyAddress) {
        require(!IStrategyToken(strategyAddress).checkIfBotIsInATrade(), "Cannot deposit or withdraw funds when bot is in a trade");
        _;
    }

    modifier onlyTradingBot {
        require(ADDRESS_RESOLVER.checkIfTradingBotAddressIsValid(msg.sender), "Only trading bot can call this function");
        _;
    }

    /* ========== EVENTS ========== */

    event DepositedFundsIntoStrategy(address user, address strategyAddress, uint amount, uint timestamp);
    event WithdrewFundsFromStrategy(address user, address strategyAddress, uint amount, uint timestamp);
    event BoughtPosition(address user, address strategyAddress, uint advertisedPrice, uint numberOfTokens, uint timestamp);
}