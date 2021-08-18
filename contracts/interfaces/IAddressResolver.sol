// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IAddressResolver {
    /**
    * @dev Given a contract name, returns the address of the contract
    * @param contractName The name of the contract
    * @return address The address associated with the given contract name
    */
    function getContractAddress(string memory contractName) external view returns (address);

    /**
    * @dev Given an address, returns whether the address belongs to a user pool
    * @param poolAddress The address to validate
    * @return bool Whether the given address is a valid user pool address
    */
    function checkIfPoolAddressIsValid(address poolAddress) external view returns (bool);

    /**
    * @dev Adds a new user pool address; meant to be called by the PoolManager contract
    * @param poolAddress The address of the user pool
    */
    function addPoolAddress(address poolAddress) external;

    function contractVerifiers(address) external view returns (address);

    function assetVerifiers(uint) external view returns (address);
}