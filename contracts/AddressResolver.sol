// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//Interfaces
import './interfaces/IAddressResolver.sol';

//Inheritance
import './Ownable.sol';

contract AddressResolver is IAddressResolver, Ownable {

    mapping (address => address) public _poolAddresses;

    mapping (address => address) public override contractVerifiers;
    mapping (uint => address) public override assetVerifiers;

    mapping (string => address) public contractAddresses;

    constructor() Ownable() {}

    /* ========== VIEWS ========== */

    /**
    * @dev Given a contract name, returns the address of the contract
    * @param contractName The name of the contract
    * @return address The address associated with the given contract name
    */
    function getContractAddress(string memory contractName) external view override returns(address) {
        require (contractAddresses[contractName] != address(0), "AddressResolver: contract not found");
        
        return contractAddresses[contractName];
    }

    /**
    * @dev Given an address, returns whether the address belongs to a pool
    * @param poolAddress The address to validate
    * @return bool Whether the given address is a valid pool address
    */
    function checkIfPoolAddressIsValid(address poolAddress) external view override returns(bool) {
        return (poolAddress != address(0)) ? (_poolAddresses[poolAddress] == poolAddress) : false;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @dev Updates the address for the given contract; meant to be called by AddressResolver owner
    * @param contractName The name of the contract
    * @param newAddress The new address for the given contract
    */
    function setContractAddress(string memory contractName, address newAddress) external onlyOwner isValidAddress(newAddress) {
        address oldAddress = contractAddresses[contractName];
        contractAddresses[contractName] = newAddress;

        emit UpdatedContractAddress(contractName, oldAddress, newAddress, block.timestamp);
    }

    /**
    * @dev Updates the verifier for the given contract
    * @param externalContract Address of the external contract
    * @param verifier Address of the contract's verifier
    */
    function setContractVerifier(address externalContract, address verifier) external onlyOwner isValidAddress(externalContract) isValidAddress(verifier) {
        contractVerifiers[externalContract] = verifier;

        emit UpdatedContractVerifier(externalContract, verifier, block.timestamp);
    }

    /**
    * @dev Updates the verifier for the given asset
    * @param assetType Type of the asset
    * @param verifier Address of the contract's verifier
    */
    function setAssetVerifier(uint assetType, address verifier) external onlyOwner isValidAddress(verifier) {
        require(assetType > 0, "AddressResolver: asset type must be greater than 0");

        assetVerifiers[assetType] = verifier;

        emit UpdatedAssetVerifier(assetType, verifier, block.timestamp);
    }

    /**
    * @dev Adds a new pool address; meant to be called by the PoolFactory contract
    * @param poolAddress The address of the pool
    */
    function addPoolAddress(address poolAddress) external override onlyPoolFactory isValidAddress(poolAddress) {
        require(_poolAddresses[poolAddress] != poolAddress, "Pool already exists");

        _poolAddresses[poolAddress] = poolAddress;
    }

    /* ========== MODIFIERS ========== */

    modifier isValidAddress(address addressToCheck) {
        require(addressToCheck != address(0), "Address is not valid");
        _;
    }

    modifier onlyPoolFactory() {
        require(msg.sender == contractAddresses["PoolFactory"], "AddressResolver: Only the PoolFactory contract can call this function");
        _;
    }

    /* ========== EVENTS ========== */

    event UpdatedContractAddress(string contractName, address oldAddress, address newAddress, uint timestamp);
    event AddedPoolAddress(address poolAddress, uint timestamp);
    event UpdatedContractVerifier(address externalContract, address verifier, uint timestamp);
    event UpdatedAssetVerifier(uint assetType, address verifier, uint timestamp);
}