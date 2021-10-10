// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

// Inheritance
import "../Ownable.sol";

// Internal references
import "../interfaces/IERC20.sol";
import "../interfaces/IAssetHandler.sol";
import "../interfaces/IAddressResolver.sol";

// Libraires
import "../libraries/SafeMath.sol";

contract Treasury is Ownable {
    using SafeMath for uint;

    IAddressResolver public immutable ADDRESS_RESOLVER;

    constructor(IAddressResolver _addressResolver) Ownable() {
        ADDRESS_RESOLVER = _addressResolver;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
    * @dev Returns amount of cUSD in this contract
    * @return uint Amount of cUSD
    */
    function getBalance() public view returns (uint) {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address stableCoinAddress = IAssetHandler(assetHandlerAddress).getStableCoinAddress();

        return IERC20(stableCoinAddress).balanceOf(address(this));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @dev Transfers cUSD to another contract or user
    * @notice Need to call cUSD.approve() before calling this function
    * @param account Address of the recipient
    * @param quantity Amount of cUSD to transfer
    */
    function transfer(address account, uint quantity) public onlyOwner {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address stableCoinAddress = IAssetHandler(assetHandlerAddress).getStableCoinAddress();

        require(account != address(0), "Invalid address");
        require(quantity > 0, "Quantity must be greater than 0");

        //Transfer cUSD to recipient
        IERC20(stableCoinAddress).transferFrom(msg.sender, account, quantity);

        emit Transfer(account, quantity, block.timestamp);
    }

    /* ========== Events ========== */

    event Transfer(address indexed account, uint quantity, uint timestamp);
}