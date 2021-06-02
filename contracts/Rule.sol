pragma solidity >=0.5.0;

import './interfaces/IRule.sol';
import './interfaces/IIndicator.sol';
import './interfaces/IComparator.sol';

contract Rule is IRule {
    address private _firstIndicatorAddress;
    address private _secondIndicatorAddress;
    address private _comparatorAddress;

    address private _tradingBotAddress;

    constructor(address firstIndicatorAddress, address secondIndicatorAddress, address comparatorAddress) public {
        _firstIndicatorAddress = firstIndicatorAddress;
        _secondIndicatorAddress = secondIndicatorAddress;
        _comparatorAddress = comparatorAddress;

        _tradingBotAddress = msg.sender;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function update(uint latestPrice) public override onlyTradingBot(msg.sender) {
        IIndicator(_firstIndicatorAddress).update(latestPrice);
        IIndicator(_secondIndicatorAddress).update(latestPrice);
    }   

    function checkConditions() public override onlyTradingBot(msg.sender) returns (bool) {
        return IComparator(_comparatorAddress).checkConditions();
    }

    /* ========== MODIFIERS ========== */

    modifier onlyTradingBot(address _caller) {
        require(_caller == _tradingBotAddress, "Only the trading bot can call this function");
        _;
    }
}