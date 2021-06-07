pragma solidity >=0.5.0;

import './Imports.sol';
import './Rule.sol';
import './AddressResolver.sol';

import './interfaces/IIndicator.sol';
import './interfaces/IComparator.sol';

contract Factory is AddressResolver {

    address[] public indicators;
    address[] public comparators;

    constructor() public {
        _setFactoryAddress(address(this));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function _generateRules(uint[] memory entryRules, uint[] memory exitRules) public onlyTradingBot(msg.sender) returns (address[] memory, address[] memory) {
        address[] memory entryRuleAddresses = new address[](entryRules.length);
        address[] memory exitRuleAddresses = new address[](exitRules.length);

        for (uint i = 0; i < entryRules.length; i++)
        {
            entryRuleAddresses[i] = _generateRule(entryRules[i], msg.sender);
        }

        for (uint i = 0; i < exitRules.length; i++)
        {
            exitRuleAddresses[i] = _generateRule(exitRules[i], msg.sender);
        }

        return (entryRuleAddresses, exitRuleAddresses);
    }

    function _addNewIndicator(address indicatorAddress) public onlyOwner() {
        require(indicatorAddress != address(0), "Invalid indicator address");

        indicators.push(indicatorAddress);

        emit AddedIndicator(indicatorAddress, indicators.length - 1, block.timestamp);
    }

    function _addNewComparator(address comparatorAddress) public onlyOwner() {
        require(comparatorAddress != address(0), "Invalid comparator address");

        comparators.push(comparatorAddress);

        emit AddedComparator(comparatorAddress, comparators.length - 1, block.timestamp);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    //first 154 bits = empty, next 6 bits = comparator, next 8 bits = first indicator, next 8 bits = second indicator, next 40 bits = first indicator param, next 40 bits = second indicator param
    function _generateRule(uint rule, address tradingBotAddress) private returns (address) {
        uint comparator = rule >> 96;
        uint firstIndicator = (rule << 160) >> 248;
        uint secondIndicator = (rule << 168) >> 248;
        uint firstIndicatorParam = (rule << 176) >> 216;
        uint secondIndicatorParam = (rule << 216) >> 216;

        address firstIndicatorAddress = _addBotToIndicator(firstIndicator, firstIndicatorParam, tradingBotAddress);
        address secondIndicatorAddress = _addBotToIndicator(secondIndicator, secondIndicatorParam, tradingBotAddress);
        address comparatorAddress = _addBotToComparator(comparator, firstIndicatorAddress, secondIndicatorAddress, tradingBotAddress);

        require(firstIndicatorAddress != address(0) && secondIndicatorAddress != address(0) && comparatorAddress != address(0), "Invalid address when generating rule");

        return address(new Rule(firstIndicatorAddress, secondIndicatorAddress, comparatorAddress, tradingBotAddress));
    }

    function _addBotToIndicator(uint indicatorIndex, uint indicatorParam, address tradingBotAddress) private returns (address) {
        require(indicatorIndex >= 0 && indicatorIndex < indicators.length, "Indicator index out of range");

        IIndicator(indicators[indicatorIndex]).addTradingBot(tradingBotAddress, indicatorParam);

        return indicators[indicatorIndex];
    }

    function _addBotToComparator(uint comparatorIndex, address firstIndicatorAddress, address secondIndicatorAddress, address tradingBotAddress) private returns (address) {
        require(comparatorIndex >= 0 && comparatorIndex < comparators.length, "Comparator index out of range");
        require(tradingBotAddress != address(0), "Invalid trading bot address");
        require(firstIndicatorAddress != address(0), "Invalid first indicator address");
        require(secondIndicatorAddress != address(0), "Invalid second indicator address");

        IComparator(comparators[comparatorIndex]).addTradingBot(tradingBotAddress, firstIndicatorAddress, secondIndicatorAddress);

        return comparators[comparatorIndex];
    }

    /* ========== EVENTS ========== */

    event AddedIndicator(address indicatorAddress, uint indicatorindex, uint timestamp);
    event AddedComparator(address comparatorAddress, uint comparatorindex, uint timestamp);
}