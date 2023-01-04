// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// Interfaces.
import './interfaces/ISettings.sol';

// Inheritance.
import './Ownable.sol';

contract Settings is ISettings, Ownable {
    mapping (string => uint) public parameters;

    /**
    * @notice Initial parameters and values:
    *         MaximumNumberOfPoolsPerUser - 2;
    *         MaximumPerformanceFee - 30% (3000 / 10000);
    *         MaximumNumberOfPositionsInPool - 6;
    *         MarketplaceProtocolFee - 1% (100 / 10000);
    *         MarketplaceAssetManagerFee - 2% (200 / 10000);
    *         MaximumNumberOfNFTPoolTokens - 1,000,000;
    *         MinimumNumberOfNFTPoolTokens - 10;
    *         MaximumNFTPoolSeedPrice - $1,000 (10 ** 21);
    *         MinimumNFTPoolSeedPrice - $0.10 (10 ** 17);
    */
    constructor() Ownable() {}

    /* ========== VIEWS ========== */

    /**
    * @notice Given the name of a parameter, returns the value of the parameter.
    * @param parameter The name of the parameter to get value for.
    * @return uint The value of the given parameter.
    */
    function getParameterValue(string memory parameter) external view override returns(uint) {
        return parameters[parameter];
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @notice Updates the address for the given contract; meant to be called by Settings contract owner.
    * @param parameter The name of the parameter to change.
    * @param newValue The new value of the given parameter.
    */
    function setParameterValue(string memory parameter, uint newValue) external onlyOwner {
        require(newValue > 0, "Settings: Value cannot be negative.");

        uint oldValue = parameters[parameter];
        parameters[parameter] = newValue;

        emit SetParameterValue(parameter, oldValue, newValue, block.timestamp);
    }

    /* ========== MODIFIERS ========== */

    modifier isValidAddress(address addressToCheck) {
        require(addressToCheck != address(0), "Settings: Address is not valid.");
        _;
    }

    /* ========== EVENTS ========== */

    event SetParameterValue(string parameter,uint oldValue, uint newValue, uint timestamp);
}