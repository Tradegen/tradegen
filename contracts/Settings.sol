// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

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
    *         WeeklyStakingFarmRewards - 500,000 TGEN; 
    *         WeeklyStableCoinStakingRewards - 500,000 TGEN;
    *         WeeklyStakingRewards - 500,000 TGEN; 
    *         TransactionFee - 0.3%;
    *         VoteLimit - 10;
    *         VotingReward - 3 TGEN;
    *         StrategyApprovalThreshold - 80%;
    *         MaximumNumberOfEntryRules - 7;
    *         MaximumNumberOfExitRules - 7;
    *         MaximumNumberOfPoolsPerUser - 2;
    *         MaximumPerformanceFee - 30%;
    *         MaximumNumberOfPositionsInPool - 6;
    *         MaximumNumberOfLeveragedPositions - 10;
    *         InterestRateOnLeveragedAssets - 4%;
    *         InterestRateOnLeveragedLiquidityPositions - 3%;
    *         LiquidationFee - 5%;
    *         TargetInsuranceFundAllocation - 50,000,000 TGEN;
    *         UBEKeeperReward - 0.1%;
    */
    constructor() public Ownable() {}

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