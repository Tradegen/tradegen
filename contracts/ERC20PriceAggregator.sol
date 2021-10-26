// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//Inheritance
import './interfaces/IPriceAggregator.sol';

//Interfaces
import './interfaces/IBaseUbeswapAdapter.sol';
import './interfaces/IAddressResolver.sol';

contract ERC20PriceAggregator is IPriceAggregator {

    IAddressResolver public ADDRESS_RESOLVER;

    constructor(IAddressResolver addressResolver) {
        ADDRESS_RESOLVER = addressResolver;
    }

    /* ========== VIEWS ========== */

    function getUSDPrice(address asset) external view override returns (uint) {
        require(asset != address(0), "ERC20PriceAggregator: invalid asset address");

        address baseUbeswapAdapterAddress = ADDRESS_RESOLVER.getContractAddress("BaseUbeswapAdapter");
        return IBaseUbeswapAdapter(baseUbeswapAdapterAddress).getPrice(asset);
    }
}