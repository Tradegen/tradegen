pragma solidity >=0.5.0;

import './AddressResolver.sol';

import './interfaces/IRule.sol';
import './interfaces/IIndicator.sol';
import './interfaces/IComparator.sol';

contract Rule is IRule, AddressResolver {
    address private _firstIndicatorAddress;
    address private _secondIndicatorAddress;
    address private _comparatorAddress;

    address private _tradingBotAddress;

    constructor(address firstIndicatorAddress, address secondIndicatorAddress, address comparatorAddress, address tradingBotAddress) public onlyFactory(msg.sender) {
        _firstIndicatorAddress = firstIndicatorAddress;
        _secondIndicatorAddress = secondIndicatorAddress;
        _comparatorAddress = comparatorAddress;

        _tradingBotAddress = tradingBotAddress;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function update(uint latestPrice) public override callerIsTradingBot(msg.sender) {
        IIndicator(_firstIndicatorAddress).update(latestPrice);
        IIndicator(_secondIndicatorAddress).update(latestPrice);
    }   

    function checkConditions() public override callerIsTradingBot(msg.sender) returns (bool) {
        return IComparator(_comparatorAddress).checkConditions();
    }

    /* ========== MODIFIERS ========== */

    modifier callerIsTradingBot(address _caller) {
        require(_caller == _tradingBotAddress, "Only the trading bot can call this function");
        _;
    }
}