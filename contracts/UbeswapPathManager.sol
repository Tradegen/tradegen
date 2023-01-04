// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// Inheritance.
import './Ownable.sol';
import './interfaces/IUbeswapPathManager.sol';

// Interfaces.
import './interfaces/IAssetHandler.sol';
import './interfaces/IAddressResolver.sol';

contract UbeswapPathManager is IUbeswapPathManager, Ownable {
    IAddressResolver public ADDRESS_RESOLVER;

    mapping (address => mapping(address => address[])) public optimalPaths;

    constructor(IAddressResolver addressResolver) Ownable() {
        ADDRESS_RESOLVER = addressResolver;
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Returns the path from 'fromAsset' to 'toAsset'.
    * @dev The path is found manually before being stored in this contract.
    * @param fromAsset Token to swap from.
    * @param toAsset Token to swap to.
    * @return address[] The pre-determined optimal path from 'fromAsset' to 'toAsset'.
    */
    function getPath(address fromAsset, address toAsset) external view override assetIsValid(fromAsset) assetIsValid(toAsset) returns (address[] memory) {
        address[] memory path = optimalPaths[fromAsset][toAsset];

        require(path.length >= 2, "UbeswapPathManager: Path not found.");

        return path;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @notice Sets the path from 'fromAsset' to 'toAsset'.
    * @dev The path is found manually before being stored in this contract.
    * @param fromAsset Token to swap from.
    * @param toAsset Token to swap to.
    * @param newPath The pre-determined optimal path between the two assets.
    */
    function setPath(address fromAsset, address toAsset, address[] memory newPath) external override onlyOwner assetIsValid(fromAsset) assetIsValid(toAsset) {
        require(newPath.length >= 2, "UbeswapPathManager: Path length must be at least 2.");
        require(newPath[0] == fromAsset, "UbeswapPathManager: First asset in path must be fromAsset.");
        require(newPath[newPath.length - 1] == toAsset, "UbeswapPathManager: Last asset in path must be toAsset.");

        optimalPaths[fromAsset][toAsset] = newPath;

        emit SetPath(fromAsset, toAsset, newPath);
    }

    /* ========== MODIFIERS ========== */

    modifier assetIsValid(address assetToCheck) {
        require(assetToCheck != address(0), "UbeswapPathManager: Asset cannot have zero address.");
        require(IAssetHandler(ADDRESS_RESOLVER.getContractAddress("AssetHandler")).isValidAsset(assetToCheck), "UbeswapPathManager: Asset not supported.");
        _;
    }

    /* ========== EVENTS ========== */

    event SetPath(address fromAsset, address toAsset, address[] newPath);
}