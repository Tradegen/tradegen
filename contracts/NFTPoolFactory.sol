// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//Interfaces
import './interfaces/ISettings.sol';
import './interfaces/IAddressResolver.sol';
import './interfaces/IMarketplace.sol';

//Internal references
import './NFTPool.sol';

contract NFTPoolFactory {
    IAddressResolver public immutable ADDRESS_RESOLVER;

    address[] public pools;
    mapping (address => uint[]) public userToManagedPools;
    mapping (address => uint) public addressToIndex; // maps to (index + 1); index 0 represents pool not found

    constructor(IAddressResolver addressResolver) {
        ADDRESS_RESOLVER = addressResolver;
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Returns the address of each pool the user manages
    * @param user Address of the user
    * @return address[] The address of each pool the user manages
    */
    function getUserManagedPools(address user) external view returns(address[] memory) {
        require(user != address(0), "Invalid address");

        address[] memory addresses = new address[](userToManagedPools[user].length);
        uint[] memory indexes = userToManagedPools[user];

        for (uint i = 0; i < addresses.length; i++)
        {
            uint index = indexes[i];
            addresses[i] = pools[index];
        }

        return addresses;
    }

    /**
    * @dev Returns the address of each available pool
    * @return address[] The address of each available pool
    */
    function getAvailablePools() external view returns(address[] memory) {
        return pools;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @dev Creates a new pool
    * @param poolName Name of the pool
    * @param maxSupply Maximum number of pool tokens
    * @param seedPrice Initial price of pool tokens
    */
    function createPool(string memory poolName, uint maxSupply, uint seedPrice) external {
        address settingsAddress = ADDRESS_RESOLVER.getContractAddress("Settings");
        uint maximumNumberOfNFTPoolTokens = ISettings(settingsAddress).getParameterValue("MaximumNumberOfNFTPoolTokens");
        uint minimumNumberOfNFTPoolTokens = ISettings(settingsAddress).getParameterValue("MinimumNumberOfNFTPoolTokens");
        uint maximumNFTPoolSeedPrice = ISettings(settingsAddress).getParameterValue("MaximumNFTPoolSeedPrice");
        uint minimumNFTPoolSeedPrice = ISettings(settingsAddress).getParameterValue("MinimumNFTPoolSeedPrice");
        uint maximumNumberOfPoolsPerUser = ISettings(settingsAddress).getParameterValue("MaximumNumberOfPoolsPerUser");
        
        require(bytes(poolName).length < 40, "Pool name must have less than 40 characters");
        require(maxSupply <= maximumNumberOfNFTPoolTokens, "Cannot exceed max supply cap");
        require(maxSupply >= minimumNumberOfNFTPoolTokens, "Cannot have less than min supply cap");
        require(seedPrice >= minimumNFTPoolSeedPrice, "Seed price must be greater than min seed price");
        require(seedPrice <= maximumNFTPoolSeedPrice, "Seed price must be less than max seed price");
        require(userToManagedPools[msg.sender].length < maximumNumberOfPoolsPerUser, "Cannot exceed maximum number of pools per user");
        
        //Create pool
        address poolAddress = address(new NFTPool());
        NFTPool(poolAddress).initialize(poolName, seedPrice, maxSupply, msg.sender, ADDRESS_RESOLVER);

        //Update state variables
        pools.push(poolAddress);
        userToManagedPools[msg.sender].push(pools.length - 1);
        addressToIndex[poolAddress] = pools.length;

        //Add pool token as sellable asset on marketplace
        address marketplaceAddress = ADDRESS_RESOLVER.getContractAddress("Marketplace");
        IMarketplace(marketplaceAddress).addAsset(poolAddress, msg.sender);

        emit CreatedNFTPool(msg.sender, poolAddress, pools.length - 1, block.timestamp);
    }

    /* ========== EVENTS ========== */

    event CreatedNFTPool(address indexed managerAddress, address indexed poolAddress, uint poolIndex, uint timestamp);
}