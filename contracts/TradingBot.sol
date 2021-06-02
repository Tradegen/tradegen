pragma solidity >=0.5.0;

import './Factory.sol';

import './libraries/SafeMath.sol';
import './interfaces/IRule.sol';

contract TradingBot is Factory {
    using SafeMath for uint;

    //parameters
    address[] private _entryRuleAddresses;
    address[] private _exitRuleAddresses;
    uint[] private _entryRules;
    uint[] private _exitRules;
    uint public _maxTradeDuration;
    uint public _profitTarget; //assumes profit target is %
    uint public _stopLoss; //assumes stop loss is %
    bool public _direction; //false = short, true = long
    string public _underlyingAssetSymbol;

    //state variables
    uint private _currentOrderSize;
    uint private _currentOrderEntryPrice;
    uint private _currentTradeDuration;

    address private oracleAddress;

    constructor(uint[] memory entryRules,
                uint[] memory exitRules,
                uint maxTradeDuration,
                uint profitTarget,
                uint stopLoss,
                bool direction,
                string memory underlyingAssetSymbol) public {
        
        _entryRules = entryRules;
        _exitRules = exitRules;
        _maxTradeDuration = maxTradeDuration;
        _profitTarget = profitTarget;
        _stopLoss = stopLoss;
        _direction = direction;
        _underlyingAssetSymbol = underlyingAssetSymbol;

        (_entryRuleAddresses, _exitRuleAddresses) = _generateRules(entryRules, exitRules);

        //TODO: set oracle address
    }

    /* ========== VIEWS ========== */

    function getTradingBotParameters() public view returns (uint[] memory, uint[] memory, uint, uint, uint, bool, string memory) {
        return (_entryRules, _exitRules, _maxTradeDuration, _profitTarget, _stopLoss, _direction, _underlyingAssetSymbol);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function onPriceFeedUpdate(uint latestPrice) public onlyOracle(msg.sender) {
        _updateRules(latestPrice);

        //check if bot is not in a trade
        if (_currentOrderSize == 0)
        {
            if (_checkEntryRules())
            {
                (_currentOrderSize, _currentOrderEntryPrice) = _placeOrder(_direction);
            }
        }
        else
        {
            if (_checkProfitTarget(latestPrice))
            {
                (_currentOrderSize, _currentOrderEntryPrice) = _placeOrder(!_direction);
            }
            else if (_checkStopLoss(latestPrice))
            {
                (_currentOrderSize, _currentOrderEntryPrice) = _placeOrder(!_direction);
            }
            else if (_currentTradeDuration >= _maxTradeDuration)
            {
                (_currentOrderSize, _currentOrderEntryPrice) = _placeOrder(!_direction);
            }
            else
            {
                _currentTradeDuration = _currentTradeDuration.add(1);
            }
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    //TODO
    function _placeOrder(bool orderType) private returns (uint, uint) {
        uint amount = 0; //get amount from TradegenERC20 balanceOf[address(this)]
        uint size = 0;
        uint price = 0;
        emit PlacedOrder(address(this), block.timestamp, _underlyingAssetSymbol, 0, 0, orderType);

        return (size, price);
    }

    function _updateRules(uint latestPrice) private {
        for (uint i = 0; i < _entryRuleAddresses.length; i++)
        {
            IRule(_entryRuleAddresses[i]).update(latestPrice);
        }

        for (uint i = 0; i < _exitRuleAddresses.length; i++)
        {
            IRule(_exitRuleAddresses[i]).update(latestPrice);
        }
    }

    function _checkEntryRules() private returns (bool) {
        for (uint i = 0; i < _entryRuleAddresses.length; i++)
        {
            if (!IRule(_entryRuleAddresses[i]).checkConditions())
            {
                return false;
            }
        }

        return true;
    }

    function _checkExitRules() private returns (bool) {
        for (uint i = 0; i < _exitRuleAddresses.length; i++)
        {
            if (!IRule(_exitRuleAddresses[i]).checkConditions())
            {
                return false;
            }
        }

        return true;
    }

    function _checkProfitTarget(uint latestPrice) private view returns (bool) {
        return _direction ? (latestPrice > _currentOrderEntryPrice.mul(1 + _profitTarget.div(100))) : (latestPrice < _currentOrderEntryPrice.mul(1 - _profitTarget.div(100)));
    }

    function _checkStopLoss(uint latestPrice) private view returns (bool) {
        return _direction ? (latestPrice < _currentOrderEntryPrice.mul(1 - _stopLoss.div(100))) : (latestPrice > _currentOrderEntryPrice.mul(1 - _stopLoss.div(100)));
    }

    /* ========== MODIFIERS ========== */

    modifier onlyOracle(address _caller) {
        require(_caller == oracleAddress, "Only the oracle can call this function");
        _;
    }

    /* ========== EVENTS ========== */

    event PlacedOrder(address tradingBotAddress, uint256 timestamp, string underlyingAssetSymbol, uint size, uint price, bool orderType);
}
