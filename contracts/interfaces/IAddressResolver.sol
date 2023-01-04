// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

interface IAddressResolver {
    /**
    * @notice Given a contract name, returns the address of the contract.
    * @param contractName The name of the contract.
    * @return address The address associated with the given contract name.
    */
    function getContractAddress(string memory contractName) external view returns (address);

    /**
    * @notice Given an address, returns whether the address belongs to a user pool.
    * @param poolAddress The address to validate.
    * @return bool Whether the given address is a valid user pool address.
    */
    function checkIfPoolAddressIsValid(address poolAddress) external view returns (bool);

    /**
    * @notice Adds a new user pool address; meant to be called by the PoolManager contract
    * @param poolAddress The address of the user pool
    */
    function addPoolAddress(address poolAddress) external;

    /**
    * @notice Returns the address of the contract verifier for the given address.
    * @dev Returns address(0) if the given address does not have a contract verifier.
    */
    function contractVerifiers(address) external view returns (address);

    /**
    * @notice Returns the address of the asset verifier for the given type.
    * @dev Returns address(0) if the given type does not have an asset verifier.
    */
    function assetVerifiers(uint) external view returns (address);
}