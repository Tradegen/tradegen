// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

//Interfaces
import './interfaces/ISettings.sol';

//Libraries
import './libraries/SafeMath.sol';

//Inheritance
import './Ownable.sol';

contract Settings is ISettings, Ownable {
    using SafeMath for uint;

    mapping (string => uint) public parameters;

    /**
    * @notice Initial parameters and values:
    *         WeeklyLPStakingRewards - 500,000 TGEN; 
    *         WeeklyStakingFarmRewards - 500,000 TGEN; 
    *         WeeklyStableCoinStakingRewards - 500,000 TGEN;
    *         WeeklyStakingRewards - 500,000 TGEN; 
    *         TransactionFee - 0.3%; (30 / 1000)
    *         VoteLimit - 10;
    *         VotingReward - 3 TGEN;
    *         StrategyApprovalThreshold - 80%;
    *         MaximumNumberOfEntryRules - 7;
    *         MaximumNumberOfExitRules - 7;
    *         MaximumNumberOfPoolsPerUser - 2;
    *         MaximumPerformanceFee - 30% (3000 / 10000);
    *         MaximumNumberOfPositionsInPool - 6;
    *         InterestRateOnLeveragedAssets - 4%;
    *         InterestRateOnLeveragedLiquidityPositions - 3%;
    *         LiquidationFee - 5%;
    *         TargetInsuranceFundAllocation - 50,000,000 TGEN;
    *         UBEKeeperReward - 0.1%;
    *         MarketplaceProtocolFee - 1% (100 / 10000)
    *         MarketplaceAssetManagerFee - 2% (200 / 10000)
    *         MaximumNumberOfNFTPoolTokens - 1,000,000
    *         MinimumNumberOfNFTPoolTokens - 10
    *         MaximumNFTPoolSeedPrice - $1,000 (10 ** 21)
    *         MinimumNFTPoolSeedPrice - $0.10 (10 ** 17)
    */
    constructor() Ownable() {}

    /* ========== VIEWS ========== */

    /**
    * @dev Given the name of a parameter, returns the value of the parameter
    * @param parameter The name of the parameter to get value for
    * @return uint The value of the given parameter
    */
    function getParameterValue(string memory parameter) public view override returns(uint) {
        return parameters[parameter];
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @dev Updates the address for the given contract; meant to be called by Settings contract owner
    * @param parameter The name of the parameter to change
    * @param newValue The new value of the given parameter
    */
    function setParameterValue(string memory parameter, uint newValue) external onlyOwner {
        require(newValue > 0, "Value cannot be negative");

        uint oldValue = parameters[parameter];
        parameters[parameter] = newValue;

        emit SetParameterValue(parameter, oldValue, newValue, block.timestamp);
    }

    /* ========== MODIFIERS ========== */

    modifier isValidAddress(address addressToCheck) {
        require(addressToCheck != address(0), "Address is not valid");
        _;
    }

    /* ========== EVENTS ========== */

    event SetParameterValue(string parameter,uint oldValue, uint newValue, uint timestamp);
}