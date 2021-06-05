pragma solidity >=0.5.0;

//libraries
import './libraries/SafeMath.sol';

import './interfaces/IERC20.sol';
import './interfaces/ITradingBot.sol';
import './interfaces/IStrategyToken.sol';

import './AddressResolver.sol';
import './StrategyProxy.sol';

contract TradingBotRewards is AddressResolver {
    using SafeMath for uint;

    struct State {
        bool debtOrYield; //true = yield, false = debt
        uint amount;
        uint circulatingSupply;
    }

    mapping(address => mapping (address => uint)) private _userToBotToLastClaimIndex; // maps to (index + 1), with index 0 representing user not having a position in the strategy
    mapping(address => State[]) private _botToStateHistory;

    constructor() public {
        _setTradingBotRewardsAddress(address(this));
    }

    /* ========== VIEWS ========== */

    function getAllAvailableYieldForBot(address tradingBotAddress) public view returns (bool, uint) {
        State[] memory history = _botToStateHistory[tradingBotAddress];
        require(history.length > 0, 'Trading bot address not valid');

        return (history[history.length - 1].debtOrYield, history[history.length - 1].amount);
    }

    function getUserAvailableYieldForBot(address user, address tradingBotAddress) public view tradingBotAddressIsValid(tradingBotAddress) returns (bool, uint) {
        return (_userToBotToLastClaimIndex[user][tradingBotAddress] > 0) ? _calculateDebtOrYield(user, tradingBotAddress) : (true, 0);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _calculateDebtOrYield(address user, address tradingBotAddress) internal returns (bool, uint) {
        address strategyAddress = ITradingBot(tradingBotAddress).getStrategyAddress();
        uint numberOfTokens = IStrategyToken(strategyAddress).getBalanceOf(user);
        State[] memory history = _botToStateHistory[tradingBotAddress];

        uint userRatio = numberOfTokens.div(history[history.length - 1].circulatingSupply);
        uint lastClaimIndex = _userToBotToLastClaimIndex[user][tradingBotAddress] - 1;

        //check for same sign
        if ((history[history.length - 1].debtOrYield && history[lastClaimIndex].debtOrYield) || (!history[history.length - 1].debtOrYield && !history[lastClaimIndex].debtOrYield))
        {
            return (history[history.length - 1].debtOrYield, userRatio.mul((history[history.length - 1].amount.sub(history[lastClaimIndex].amount))));
        }
        //user initially had yield and now has debt
        else if (history[history.length - 1].debtOrYield && !history[lastClaimIndex].debtOrYield)
        {
            return (history[history.length - 1].amount >= history[lastClaimIndex].amount) ? (false, history[history.length - 1].amount.sub(history[lastClaimIndex].amount)) : (true, history[lastClaimIndex].amount.sub(history[history.length - 1].amount));
        }
        //user initially had debt and now has yield
        else
        {
            return (history[history.length - 1].amount >= history[lastClaimIndex].amount) ? (true, history[history.length - 1].amount.sub(history[lastClaimIndex].amount)) : (false, history[lastClaimIndex].amount.sub(history[history.length - 1].amount));
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function updateRewards(bool profitOrLoss, uint amount, uint circulatingSupply) public onlyTradingBot(msg.sender) {
        State[] storage history = _botToStateHistory[msg.sender];

        if (history.length > 0)
        {
            //check for same sign
            if ((history[history.length - 1].debtOrYield && profitOrLoss) || (!history[history.length - 1].debtOrYield && !profitOrLoss))
            {
                amount = amount.add(history[history.length - 1].amount);
            }
            //current yield is positive and bot made losing trade
            else if (history[history.length - 1].debtOrYield && !profitOrLoss)
            {
                (profitOrLoss, amount) = (history[history.length - 1].amount >= amount) ? (true, history[history.length - 1].amount.sub(amount)) : (false, amount.sub(history[history.length - 1].amount));
            }
            //current yield is negative and bot made profitable trade
            else
            {
                (profitOrLoss, amount) = (amount >= history[history.length - 1].amount) ? (true, amount.sub(history[history.length - 1].amount)) : (false, history[history.length - 1].amount.sub(amount));
            }
        }

        history.push(State(profitOrLoss, amount, circulatingSupply));

        emit UpdatedRewards(msg.sender, profitOrLoss, amount, block.timestamp);
    }

    function claim(address tradingBotAddress) public userHasAPosition(msg.sender) tradingBotAddressIsValid(tradingBotAddress) {
        (bool debtOrYield, uint amount) = _calculateDebtOrYield(msg.sender, tradingBotAddress);
        StrategyProxy(getStrategyProxyAdddress())._claim(msg.sender, debtOrYield, amount);
        _userToBotToLastClaimIndex[msg.sender][tradingBotAddress] = _botToStateHistory[tradingBotAddress].length;

        emit Claimed(msg.sender, tradingBotAddress, debtOrYield, amount, block.timestamp);
    }

    /* ========== MODIFIERS ========== */

    modifier userHasAPosition(address user, address tradingBotAddress) {
        require(_userToBotToLastClaimIndex[user][tradingBotAddress] > 0, "Need to have a position to claim yield");
        _;
    }

    modifier userHasNotClaimedYet(address user, address tradingBotAddress) {
        require(_userToBotToLastClaimIndex[user][tradingBotAddress] < _botToStateHistory[tradingBotAddress].length, "Already claimed available yield");
        _;
    }

    modifier tradingBotAddressIsValid(address tradingBotAddress) {
        require(_botToStateHistory[tradingBotAddress].length > 0, "Invalid trading bot address");
        _;
    }

    /* ========== EVENTS ========== */

    event UpdatedRewards(address indexed tradingBot, bool profitOrLoss, uint amount, uint timestamp);
    event Claimed(address indexed user, address indexed tradingBot, bool debtOrYield, uint amount, uint timestamp);
}