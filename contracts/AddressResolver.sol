pragma solidity >=0.5.0;

import './Ownable.sol';

contract AddressResolver is Ownable {
    address public _baseTradegenAddress;
    address public _stakingRewardsAddress;
    address public _tradingBotRewardsAddress;
    address public _strategyProxyAddress;
    address public _settingsAddress;
    address public _strategyApprovalAddress;
    address public _strategyManagerAddress;
    address public _userManagerAddress;
    address public _componentsAddress;

    mapping (address => address) public _tradingBotAddresses;
    mapping (address => address) public _strategyAddresses;

    constructor() public Ownable() {
    }

    /* ========== VIEWS ========== */

    function getBaseTradegenAddress() public view returns (address) {
        return _baseTradegenAddress;
    }

    function getStakingRewardsAddress() public view returns (address) {
        return _stakingRewardsAddress;
    }

    function getTradingBotRewardsAddress() public view returns (address) {
        return _tradingBotRewardsAddress;
    }

    function getStrategyProxyAddress() public view returns (address) {
        return _strategyProxyAddress;
    }

    function getSettingsAddress() public view returns (address) {
        return _settingsAddress;
    }

    function getStrategyApprovalAddress() public view returns (address) {
        return _strategyApprovalAddress;
    }

    function getStrategyManagerAddress() public view returns (address) {
        return _strategyManagerAddress;
    }

    function getUserManagerAddress() public view returns (address) {
        return _userManagerAddress;
    }

    function getComponentsAddress() public view returns (address) {
        return _componentsAddress;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _setBaseTradegenAddress(address baseTradegenAddress) internal isValidAddress(baseTradegenAddress) {
        _baseTradegenAddress = baseTradegenAddress;
    }

    function _setStakingRewardsAddress(address stakingRewardsAddress) internal isValidAddress(stakingRewardsAddress) {
        _stakingRewardsAddress = stakingRewardsAddress;
    }

    function _setTradingBotRewardsAddress(address tradingBotRewardsAddress) internal isValidAddress(tradingBotRewardsAddress) {
        _tradingBotRewardsAddress = tradingBotRewardsAddress;
    }

    function _setSettingsAddress(address settingsAddress) internal isValidAddress(settingsAddress) {
        _settingsAddress = settingsAddress;
    }

    function _setStrategyApprovalAddress(address strategyApprovalAddress) internal isValidAddress(strategyApprovalAddress) {
        _strategyApprovalAddress = strategyApprovalAddress;
    }

    function _setStrategyManagerAddress(address strategyManagerAddress) internal isValidAddress(strategyManagerAddress) {
        _strategyManagerAddress = strategyManagerAddress;
    }

    function _setUserManagerAddress(address userManagerAddress) internal isValidAddress(userManagerAddress) {
        _userManagerAddress = userManagerAddress;
    }

    function _setComponentsAddress(address componentsAddress) internal isValidAddress(componentsAddress) {
        _componentsAddress = componentsAddress;
    }

    function _addTradingBotAddress(address tradingBotAddress) internal isValidAddress(tradingBotAddress) onlyStrategy(msg.sender) {
        _tradingBotAddresses[tradingBotAddress] = tradingBotAddress;
    }

    function _addStrategyAddress(address strategyAddress) internal isValidAddress(strategyAddress) onlyStrategyManager(msg.sender) {
        _strategyAddresses[strategyAddress] = strategyAddress;
    }

    /* ========== MODIFIERS ========== */

    modifier isValidAddress(address addressToCheck) {
        require(addressToCheck != address(0), "Address is not valid");
        _;
    }

    modifier isValidStrategyAddress(address _strategyAddress) {
        require(_strategyAddresses[_strategyAddress] == _strategyAddress, "Strategy address not found");
        _;
    }

    modifier validAddressForTransfer(address addressToCheck) {
        require(addressToCheck == _stakingRewardsAddress || addressToCheck == _strategyProxyAddress || addressToCheck == _strategyApprovalAddress || addressToCheck == _componentsAddress, "Address is not valid");
        _;
    }

    modifier onlyTradingBot(address addressToCheck) {
        require(addressToCheck == _tradingBotAddresses[addressToCheck], "Only the trading bot can call this function");
        _;
    }

    modifier onlyStrategy(address addressToCheck) {
        require(addressToCheck == _strategyAddresses[addressToCheck], "Only the Strategy contract can call this function");
        _;
    }

    modifier onlyTradingBotRewards(address addressToCheck) {
        require(addressToCheck == _tradingBotRewardsAddress, "Only TradingBotRewards can call this function");
        _;
    }

    modifier onlyProxy(address addressToCheck) {
        require(addressToCheck == _strategyProxyAddress, "Only the strategy proxy can call this function");
        _;
    }

    modifier onlyStrategyManager(address addressToCheck) {
        require(addressToCheck == _strategyManagerAddress, "Only the Strategy Manager contract can call this function");
        _;
    }
}