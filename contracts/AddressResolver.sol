pragma solidity >=0.5.0;

import './Ownable.sol';

contract AddressResolver is Ownable {
    address public _baseTradegenAddress;
    address public _stakingRewardsAddress;
    address public _tradingBotRewardsAddress;
    address public _strategyProxyAddress;
    address public _settingsAddress;
    address public _strategyApprovalAddress;
    address public _userManagerAddress;
    address public _factoryAddress;
    address public _importsAddress;

    mapping (address => address) public _tradingBotAddresses;
    mapping (address => address) public _strategyAddresses;

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

    function getUserManagerAddress() public view returns (address) {
        return _userManagerAddress;
    }

    function getFactoryAddress() public view returns (address) {
        return _factoryAddress;
    }

    function getImportsAddress() public view returns (address) {
        return _importsAddress;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _setBaseTradegenAddress(address baseTradegenAddress) internal isValidAddress(baseTradegenAddress) {
        _baseTradegenAddress = baseTradegenAddress;
    }

    function _setFactoryAddress(address factoryAddress) internal isValidAddress(factoryAddress) {
        _factoryAddress = factoryAddress;
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

    function _setUserManagerAddress(address userManagerAddress) internal isValidAddress(userManagerAddress) {
        _userManagerAddress = userManagerAddress;
    }

    function _addTradingBotAddress(address tradingBotAddress) internal isValidAddress(tradingBotAddress) {
        _tradingBotAddresses[tradingBotAddress] = tradingBotAddress;
    }

    function _addStrategyAddress(address strategyAddress) internal isValidAddress(strategyAddress) {
        _strategyAddresses[strategyAddress] = strategyAddress;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function _setImportsAddress(address importsAddress) public isValidAddress(importsAddress) onlyOwner() {
        _importsAddress = importsAddress;
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
        require(addressToCheck == _stakingRewardsAddress || addressToCheck == _strategyProxyAddress || addressToCheck == _strategyApprovalAddress, "Address is not valid");
        _;
    }

    modifier onlyTradingBot(address addressToCheck) {
        require(addressToCheck == _tradingBotAddresses[addressToCheck], "Only the trading bot can call this function");
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

    modifier onlyFactory(address addressToCheck) {
        require(addressToCheck == _factoryAddress, "Only the factory can call this function");
        _;
    }

    modifier onlyImports(address addressToCheck) {
        require(addressToCheck == _importsAddress, "Only the Imports contract can call this function");
        _;
    }
}