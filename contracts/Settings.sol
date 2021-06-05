pragma solidity >=0.5.0;

import './libraries/SafeMath.sol';

import './AddressResolver.sol';

contract Settings is AddressResolver {
    using SafeMath for uint;

    uint public stakingYield; //APY% for staking rewards
    uint public transactionFee; //initialy 0.3%
    uint public voteLimit;
    uint public votingReward;
    uint public votingPenalty;
    uint public minimumStakeToVote;
    uint public strategyApprovalThreshold;
    uint public maximumNumberOfEntryRules;
    uint public maximumNumberOfExitRules;

    mapping (uint => string) public underlyingAssetIDToSymbol;
    mapping (uint => address) public underlyingAssetIDToOracleAddress;
    mapping(string => uint) public symbolToUnderlyingAssetID;

    constructor() public {
        voteLimit = 10;
        stakingYield = 12;
        transactionFee = 3;

        _setSettingsAddress(address(this));
    }

    /* ========== VIEWS ========== */

    function checkIfSymbolIDIsValid(uint symbolID) public view returns (bool) {
        return (symbolID >= 0 && underlyingAssetIDToOracleAddress[symbolID] != address(0));
    }

    function getVoteLimit() public view returns (uint) {
        return voteLimit;
    }

    function getVotingReward() public view returns (uint) {
        return votingReward;
    }

    function getVotingPenalty() public view returns (uint) {
        return votingPenalty;
    }

    function getStrategyApprovalThreshold() public view returns (uint) {
        return strategyApprovalThreshold;
    }
}