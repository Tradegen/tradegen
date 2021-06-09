pragma solidity >=0.5.0;

import './Settings.sol';
import './TradingBotRewards.sol';
import './AddressResolver.sol';
import './Components.sol';

import './libraries/SafeMath.sol';

import './interfaces/IStrategyToken.sol';
import './interfaces/ITradingBot.sol';
import './interfaces/IIndicator.sol';
import './interfaces/IComparator.sol';

contract TradingBot is ITradingBot, AddressResolver {
    using SafeMath for uint;

    //parameters
    Rule[] private _entryRules;
    Rule[] private _exitRules;
    uint public _maxTradeDuration;
    uint public _profitTarget; //assumes profit target is %
    uint public _stopLoss; //assumes stop loss is %
    bool public _direction; //false = short, true = long
    uint public _underlyingAssetSymbol;

    //state variables
    uint private _currentOrderSize;
    uint private _currentOrderEntryPrice;
    uint private _currentTradeDuration;

    address private _oracleAddress;
    address private _strategyAddress;

    constructor(uint[] memory entryRules,
                uint[] memory exitRules,
                uint maxTradeDuration,
                uint profitTarget,
                uint stopLoss,
                bool direction,
                uint underlyingAssetSymbol) public onlyStrategy(msg.sender) {
        
        _maxTradeDuration = maxTradeDuration;
        _profitTarget = profitTarget;
        _stopLoss = stopLoss;
        _direction = direction;
        _underlyingAssetSymbol = underlyingAssetSymbol;

        _strategyAddress = msg.sender;
        _oracleAddress = Settings(getSettingsAddress()).getOracleAddress(underlyingAssetSymbol);

        _generateRules(entryRules, exitRules);
    }

    /* ========== VIEWS ========== */

    function getTradingBotParameters() public view override returns (Rule[] memory, Rule[] memory, uint, uint, uint, bool, uint) {
        return (_entryRules, _exitRules, _maxTradeDuration, _profitTarget, _stopLoss, _direction, _underlyingAssetSymbol);
    }

    function getStrategyAddress() public view override onlyTradingBotRewards(msg.sender) returns (address) {
        return _strategyAddress;
    }

    function checkIfBotIsInATrade() public view override returns (bool) {
        return (_currentOrderSize == 0);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function onPriceFeedUpdate(uint latestPrice) public override onlyOracle(msg.sender) {
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
            if (_checkProfitTarget(latestPrice) || _checkStopLoss(latestPrice) || _currentTradeDuration >= _maxTradeDuration)
            {
                (, uint exitPrice) = _placeOrder(!_direction);
                (bool profitOrLoss, uint amount) = _calculateProfitOrLoss(exitPrice);
                _currentOrderEntryPrice = 0;
                _currentOrderSize = 0;
                _currentTradeDuration = 0;
                TradingBotRewards(getTradingBotRewardsAddress()).updateRewards(profitOrLoss, amount, IStrategyToken(_strategyAddress).getCirculatingSupply());
            }
            else
            {
                _currentTradeDuration = _currentTradeDuration.add(1);
            }
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    //TODO: send order to decentralized exchange
    function _placeOrder(bool orderType) private returns (uint, uint) {
        uint amount = 0; //get amount from TradegenERC20 balanceOf[address(this)]
        uint size = 0;
        uint price = 0;
        emit PlacedOrder(address(this), block.timestamp, _underlyingAssetSymbol, 0, 0, orderType);

        return (size, price);
    } 

    function _calculateProfitOrLoss(uint exitPrice) private view returns (bool, uint) {
        return (exitPrice >= _currentOrderEntryPrice) ? (true, exitPrice.sub(_currentOrderEntryPrice).div(_currentOrderEntryPrice)) : (false, _currentOrderEntryPrice.sub(exitPrice).div(_currentOrderEntryPrice));
    }

    function _updateRules(uint latestPrice) private {
        for (uint i = 0; i < _entryRules.length; i++)
        {
            IIndicator(_entryRules[i].firstIndicatorAddress).update(latestPrice);
            IIndicator(_entryRules[i].secondIndicatorAddress).update(latestPrice);
        }

        for (uint i = 0; i < _exitRules.length; i++)
        {
            IIndicator(_exitRules[i].firstIndicatorAddress).update(latestPrice);
            IIndicator(_exitRules[i].secondIndicatorAddress).update(latestPrice);
        }
    }

    function _checkEntryRules() private returns (bool) {
        for (uint i = 0; i < _entryRules.length; i++)
        {
            if (!IComparator(_entryRules[i].comparatorAddress).checkConditions())
            {
                return false;
            }
        }

        return true;
    }

    function _checkExitRules() private returns (bool) {
        for (uint i = 0; i < _exitRules.length; i++)
        {
            if (!IComparator(_exitRules[i].comparatorAddress).checkConditions())
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

    function _generateRules(uint[] memory entryRules, uint[] memory exitRules) internal {

        for (uint i = 0; i < entryRules.length; i++)
        {
            _entryRules.push(_generateRule(entryRules[i]));
        }

        for (uint i = 0; i < exitRules.length; i++)
        {
             _exitRules.push(_generateRule(exitRules[i]));
        }
    }

    //first 154 bits = empty, next 6 bits = comparator, next 8 bits = first indicator, next 8 bits = second indicator, next 40 bits = first indicator param, next 40 bits = second indicator param
    function _generateRule(uint rule) private returns (Rule memory) {
        uint comparator = rule >> 96;
        uint firstIndicator = (rule << 160) >> 248;
        uint secondIndicator = (rule << 168) >> 248;
        uint firstIndicatorParam = (rule << 176) >> 216;
        uint secondIndicatorParam = (rule << 216) >> 216;

        address firstIndicatorAddress = _addBotToIndicator(firstIndicator, firstIndicatorParam);
        address secondIndicatorAddress = _addBotToIndicator(secondIndicator, secondIndicatorParam);
        address comparatorAddress = _addBotToComparator(comparator, firstIndicatorAddress, secondIndicatorAddress);

        require(firstIndicatorAddress != address(0) && secondIndicatorAddress != address(0) && comparatorAddress != address(0), "Invalid address when generating rule");

        return Rule(firstIndicatorAddress, secondIndicatorAddress, comparatorAddress);
    }

    function _addBotToIndicator(uint indicatorIndex, uint indicatorParam) private returns (address) {
        address[] memory indicators = Components(getComponentsAddress()).getIndicators();

        require(indicatorIndex >= 0 && indicatorIndex < indicators.length, "Indicator index out of range");

        IIndicator(indicators[indicatorIndex]).addTradingBot(indicatorParam);

        return indicators[indicatorIndex];
    }

    function _addBotToComparator(uint comparatorIndex, address firstIndicatorAddress, address secondIndicatorAddress) private returns (address) {
        address[] memory comparators = Components(getComponentsAddress()).getComparators();

        require(comparatorIndex >= 0 && comparatorIndex < comparators.length, "Comparator index out of range");
        require(firstIndicatorAddress != address(0), "Invalid first indicator address");
        require(secondIndicatorAddress != address(0), "Invalid second indicator address");

        IComparator(comparators[comparatorIndex]).addTradingBot(firstIndicatorAddress, secondIndicatorAddress);

        return comparators[comparatorIndex];
    }

    /* ========== MODIFIERS ========== */

    modifier onlyOracle(address _caller) {
        require(_caller == _oracleAddress, "Only the oracle can call this function");
        _;
    }

    /* ========== EVENTS ========== */

    event PlacedOrder(address tradingBotAddress, uint256 timestamp, uint underlyingAssetSymbol, uint size, uint price, bool orderType);
}
