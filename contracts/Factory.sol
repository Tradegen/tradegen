pragma solidity >=0.5.0;

import './Imports.sol';
import './Rule.sol';

import './interfaces/IIndicator.sol';
import './interfaces/IComparator.sol';

contract Factory is Imports {

    function _generateRules(uint[] memory entryRules, uint[] memory exitRules) internal returns (address[] memory, address[] memory) {
        address[] memory entryRuleAddresses = new address[](entryRules.length);
        address[] memory exitRuleAddresses = new address[](exitRules.length);

        for (uint i = 0; i < entryRules.length; i++)
        {
            entryRuleAddresses[i] = _generateRule(entryRules[i]);
        }

        for (uint i = 0; i < exitRules.length; i++)
        {
            exitRuleAddresses[i] = _generateRule(exitRules[i]);
        }

        return (entryRuleAddresses, exitRuleAddresses);
    }

    //first 154 bits = empty, next 6 bits = comparator, next 8 bits = first indicator, next 8 bits = second indicator, next 40 bits = first indicator param, next 40 bits = second indicator param
    function _generateRule(uint rule) private returns (address) {
        uint comparator = rule >> 96;
        uint firstIndicator = (rule << 160) >> 248;
        uint secondIndicator = (rule << 168) >> 248;
        uint firstIndicatorParam = (rule << 176) >> 216;
        uint secondIndicatorParam = (rule << 216) >> 216;

        address firstIndicatorAddress = _generateIndicator(firstIndicator, firstIndicatorParam);
        address secondIndicatorAddress = _generateIndicator(secondIndicator, secondIndicatorParam);
        address comparatorAddress = _generateComparator(comparator, firstIndicatorAddress, secondIndicatorAddress);

        return address(new Rule(firstIndicatorAddress, secondIndicatorAddress, comparatorAddress));
    }
}