pragma solidity >=0.5.0;

//libraries
import './libraries/SafeMath.sol';

import './interfaces/IERC20.sol';

import './AddressResolver.sol';

contract TradingBotRewards is AddressResolver {
    using SafeMath for uint;

    struct State {
        bool debtOrYield;
        uint amount;
        uint circulatingSupply;
    }

    mapping(address => uint) private _userToLastClaimIndex;
    mapping(address => State[]) private _botToStateHistory;

    constructor() public {
        _setTradingBotRewardsAddress(address(this));
    }

    /* ========== VIEWS ========== */

    function getAvailableYield(address tradingBotAddress) public view returns (bool, uint) {
        State[] memory history = _botToStateHistory[tradingBotAddress];
        require(history.length > 0, 'Trading bot address not valid');

        return (history[history.length - 1].debtOrYield, history[history.length - 1].amount);
    }

    /* ========== INTERNAL FUNCTIONS ========== */


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

    /* ========== EVENTS ========== */

    event UpdatedRewards(address indexed tradingBot, bool profitOrLoss, uint amount, uint timestamp);
    event Claimed(address indexed user, address indexed tradingBot, bool debtOrYield, uint amount, uint timestamp);
}