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

    address public cUSDaddress;
    address[] public availableCurrencies;
    mapping (address => uint) public currencyKeyToIndex; //maps to (index + 1); index 0 represents currency key not found
    mapping (string => address) public currencySymbolToAddress;

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
        return (symbolID > 0 && underlyingAssetIDToOracleAddress[symbolID] != address(0));
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

    function getStakingYield() public view returns (uint) {
        return stakingYield;
    }

    function getStrategyApprovalThreshold() public view returns (uint) {
        return strategyApprovalThreshold;
    }

    function getTransactionFee() public view returns (uint) {
        return transactionFee;
    }

    function getMaximumNumberOfEntryRules() public view returns (uint) {
        return maximumNumberOfEntryRules;
    }

    function getMaximumNumberOfExitRules() public view returns (uint) {
        return maximumNumberOfExitRules;
    }

    function getOracleAddress(uint underlyingAssetID) public view returns (address) {
        return underlyingAssetIDToOracleAddress[underlyingAssetID];
    }

    function getUnderlyingAssetSymbol(uint underlyingAssetID) public view returns (string memory) {
        return underlyingAssetIDToSymbol[underlyingAssetID];
    }

    function getAvailableCurrencies() public view returns (address[] memory) {
        return availableCurrencies;
    }

    function checkIfCurrencyIsAvailable(address currency) public view returns (bool) {
        require(currency != address(0), "Invalid currency key");

        return currencyKeyToIndex[currency] > 0;
    }

    function getStableCurrencyAddress() public view returns (address) {
        return cUSDaddress;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function addNewAsset(uint underlyingAssetID, string memory symbol, address oracleAddress) public onlyOwner() {
        require(oracleAddress != address(0), "Invalid oracle address");
        require(underlyingAssetID > 0, "Asset ID out of range");
        require(underlyingAssetIDToOracleAddress[underlyingAssetID] == address(0), "Asset already exists");
        require(symbolToUnderlyingAssetID[symbol] == 0, "Symbol already exists");

        underlyingAssetIDToOracleAddress[underlyingAssetID] = oracleAddress;
        underlyingAssetIDToSymbol[underlyingAssetID] = symbol;
        symbolToUnderlyingAssetID[symbol] = underlyingAssetID;

        emit AddedAsset(underlyingAssetID, symbol, oracleAddress, block.timestamp);
    }

    function updateOracleAddress(uint underlyingAssetID, address newOracleAddress) public onlyOwner() {
        require(newOracleAddress != address(0), "Invalid oracle address");

        underlyingAssetIDToOracleAddress[underlyingAssetID] = newOracleAddress;

        emit UpdatedOracleAddress(underlyingAssetID, newOracleAddress, block.timestamp);
    }

    function setStakingYield(uint newYield) public onlyOwner() {
        require(newYield > 0, "Yield cannot be 0");

        stakingYield = newYield;

        emit UpdatedStakingYield(newYield, block.timestamp);
    }

    function setTransactionFee(uint newTransactionFee) public onlyOwner() {
        require(newTransactionFee > 0, "Transaction fee cannot be 0");

        transactionFee = newTransactionFee;

        emit UpdatedStakingYield(newTransactionFee, block.timestamp);
    }

    function setVoteLimit(uint newVoteLimit) public onlyOwner() {
        require(newVoteLimit > 0, "Vote limit cannot be 0");

        voteLimit = newVoteLimit;

        emit UpdatedStakingYield(newVoteLimit, block.timestamp);
    }

    function setVotingReward(uint newVotingReward) public onlyOwner() {
        require(newVotingReward > 0, "Voting reward cannot be 0");

        votingReward = newVotingReward;

        emit UpdatedVotingReward(newVotingReward, block.timestamp);
    }

    function setVotingPenalty(uint newVotingPenalty) public onlyOwner() {
        require(newVotingPenalty > 0, "Voting penalty cannot be 0");

        votingPenalty = newVotingPenalty;

        emit UpdatedVotingPenalty(newVotingPenalty, block.timestamp);
    }

    function setMinimumStakeToVote(uint newMinimumStakeToVote) public onlyOwner() {
        require(newMinimumStakeToVote > 0, "Minimum stake cannot be 0");

        minimumStakeToVote = newMinimumStakeToVote;

        emit UpdatedMinimumStakeToVote(newMinimumStakeToVote, block.timestamp);
    }

    function setStrategyApprovalThreshold(uint newStrategyApprovalThreshold) public onlyOwner() {
        require(newStrategyApprovalThreshold > 0, "Strategy approval threshold cannot be 0");
        require(newStrategyApprovalThreshold < voteLimit, "Strategy approval threshold must be less than vote limit");

        strategyApprovalThreshold = newStrategyApprovalThreshold;

        emit UpdatedStrategyApprovalThreshold(newStrategyApprovalThreshold, block.timestamp);
    }

    function setMaximumNumberOfEntryRules(uint newMaximumNumberOfEntryRules) public onlyOwner() {
        require(newMaximumNumberOfEntryRules > 0, "Maximum number of entry rules cannot be 0");

        maximumNumberOfEntryRules = newMaximumNumberOfEntryRules;

        emit UpdatedMaximumNumberOfEntryRules(newMaximumNumberOfEntryRules, block.timestamp);
    }

    function setMaximumNumberOfExitRules(uint newMaximumNumberOfExitRules) public onlyOwner() {
        require(newMaximumNumberOfExitRules > 0, "Maximum number of exit rules cannot be 0");

        maximumNumberOfExitRules = newMaximumNumberOfExitRules;

        emit UpdatedMaximumNumberOfExitRules(newMaximumNumberOfExitRules, block.timestamp);
    }

    function setStableCurrencyAddress(address stableCurrencyAddress) public onlyOwner() {
        require(stableCurrencyAddress != address(0), "Invalid address");

        cUSDaddress = stableCurrencyAddress;

        emit UpdatedStableCurrencyAddress(stableCurrencyAddress, block.timestamp);
    }

    function updateCurrencyKey(string memory currencySymbol, address newCurrencyKey) public onlyOwner() {
        require(newCurrencyKey != address(0), "Invalid address");
        require(newCurrencyKey != cUSDaddress, "New currency key cannot equal stable token address");
        require(currencyKeyToIndex[newCurrencyKey] == 0, "New currency key already exists");
        require(currencySymbolToAddress[currencySymbol] != address(0), "Currency symbol not found");

        address oldCurrencyKey = currencySymbolToAddress[currencySymbol];
        uint oldCurrencyKeyIndex = currencyKeyToIndex[oldCurrencyKey];

        availableCurrencies[oldCurrencyKeyIndex - 1] = newCurrencyKey;
        currencyKeyToIndex[newCurrencyKey] = oldCurrencyKeyIndex;
        currencySymbolToAddress[currencySymbol] = newCurrencyKey;

        delete currencyKeyToIndex[oldCurrencyKey];

        emit UpdatedCurrencyKey(currencySymbol, newCurrencyKey, block.timestamp);
    }

    function addCurrencyKey(string memory currencySymbol, address currencyKey) public onlyOwner() {
        require(currencyKey != address(0), "Invalid address");
        require(currencyKey != cUSDaddress, "Cannot equal stable token address");
        require(currencyKeyToIndex[currencyKey] == 0, "Currency key already exists");
        require(currencySymbolToAddress[currencySymbol] == address(0), "Currency symbol already exists");

        availableCurrencies.push(currencyKey);
        currencyKeyToIndex[currencyKey] = availableCurrencies.length;
        currencySymbolToAddress[currencySymbol] = currencyKey;

        emit UpdatedStableCurrencyAddress(currencyKey, block.timestamp);
    }

    /* ========== EVENTS ========== */

    event AddedAsset(uint underlyingAssetID, string symbol, address oracleAddress, uint timestamp);
    event AddedCurrencyKey(address currencyKey, uint timestamp);
    event UpdatedOracleAddress(uint underlyingAssetID, address newOracleAddress, uint timestamp);
    event UpdatedStakingYield(uint newYield, uint timestamp);
    event UpdatedTransactionFee(uint newTransactionFee, uint timestamp);
    event UpdatedVoteLimit(uint newVoteLimit, uint timestamp);
    event UpdatedVotingReward(uint newVotingReward, uint timestamp);
    event UpdatedVotingPenalty(uint newVotingPenalty, uint timestamp);
    event UpdatedMinimumStakeToVote(uint newMinimumStakeToVote, uint timestamp);
    event UpdatedStrategyApprovalThreshold(uint newStrategyApprovalThreshold, uint timestamp);
    event UpdatedMaximumNumberOfEntryRules(uint newMaximumNumberOfEntryRules, uint timestamp);
    event UpdatedMaximumNumberOfExitRules(uint newMaximumNumberOfExitRules, uint timestamp);
    event UpdatedStableCurrencyAddress(address stableCurrencyAddress, uint timestamp);
    event UpdatedCurrencyKey(string currencySymbol, address newCurrencyKey, uint timestamp);   
}