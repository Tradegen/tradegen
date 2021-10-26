// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

//Libraries
import "../libraries/TxDataUtils.sol";
import "../openzeppelin-solidity/SafeMath.sol";

//Inheritance
import "../interfaces/IVerifier.sol";

//Interfaces
import "../interfaces/IAddressResolver.sol";
import "../interfaces/IAssetHandler.sol";
import "../interfaces/IBaseUbeswapAdapter.sol";

contract UbeswapRouterVerifier is TxDataUtils, IVerifier {
    using SafeMath for uint;

    /**
    * @dev Parses the transaction data to make sure the transaction is valid
    * @param addressResolver Address of AddressResolver contract
    * @param pool Address of the pool
    * @param data Transaction call data
    * @return (uint, address) Whether the transaction is valid and the received asset
    */
    function verify(address addressResolver, address pool, address, bytes calldata data) external override returns (bool, address) {
        bytes4 method = getMethod(data);

        address assetHandlerAddress = IAddressResolver(addressResolver).getContractAddress("AssetHandler");
        address baseUbeswapAdapterAddress = IAddressResolver(addressResolver).getContractAddress("BaseUbeswapAdapter");

        if (method == bytes4(keccak256("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)")))
        {
            //Parse transaction data
            address srcAsset = convert32toAddress(getArrayIndex(data, 2, 0)); // gets the second input (path) first item (token to swap from)
            address dstAsset = convert32toAddress(getArrayLast(data, 2)); // gets second input (path) last item (token to swap to)
            uint srcAmount = uint(getInput(data, 0));
            address toAddress = convert32toAddress(getInput(data, 3));

            //Check if assets are supported
            require(IAssetHandler(assetHandlerAddress).isValidAsset(srcAsset), "UbeswapRouterVerifier: unsupported source asset");
            require(IAssetHandler(assetHandlerAddress).isValidAsset(dstAsset), "UbeswapRouterVerifier: unsupported destination asset");

            //Check if recipient is a pool
            require(pool == toAddress, "UbeswapRouterVerifier: recipient is not pool");

            emit Swap(pool, srcAsset, dstAsset, srcAmount, block.timestamp);

            return (true, dstAsset);
        }
        else if (method == bytes4(keccak256("addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)")))
        {
            address tokenA = convert32toAddress(getInput(data, 0));
            address tokenB = convert32toAddress(getInput(data, 1));

            uint amountADesired = uint(getInput(data, 2));
            uint amountBDesired = uint(getInput(data, 3));

            //Check if assets are supported
            address pair = IBaseUbeswapAdapter(baseUbeswapAdapterAddress).getPair(tokenA, tokenB);
            require(IAssetHandler(assetHandlerAddress).isValidAsset(tokenA), "UbeswapRouterVerifier: unsupported tokenA");
            require(IAssetHandler(assetHandlerAddress).isValidAsset(tokenB), "UbeswapRouterVerifier: unsupported tokenB");
            require(IAssetHandler(assetHandlerAddress).isValidAsset(pair), "UbeswapRouterVerifier: unsupported LP token");

            address recipient = convert32toAddress(getInput(data, 6));

            //Check if recipient is a pool
            require(pool == recipient, "UbeswapRouterVerifier: recipient is not pool");

            emit AddedLiquidity(pool, tokenA, tokenB, pair, amountADesired, amountBDesired, block.timestamp);

            return (true, pair);
        }
        else if (method == bytes4(keccak256("removeLiquidity(address,address,uint256,uint256,uint256,address,uint256)")))
        {
            address tokenA = convert32toAddress(getInput(data, 0));
            address tokenB = convert32toAddress(getInput(data, 1));

            uint numberOfLPTokens = uint(getInput(data, 2));

            //Check if assets are supported
            address pair = IBaseUbeswapAdapter(baseUbeswapAdapterAddress).getPair(tokenA, tokenB);
            require(IAssetHandler(assetHandlerAddress).isValidAsset(tokenA), "UbeswapRouterVerifier: unsupported tokenA");
            require(IAssetHandler(assetHandlerAddress).isValidAsset(tokenB), "UbeswapRouterVerifier: unsupported tokenB");
            require(IAssetHandler(assetHandlerAddress).isValidAsset(pair), "UbeswapRouterVerifier: unsupported LP token");

            //Check if recipient is a pool
            require(pool == convert32toAddress(getInput(data, 5)), "UbeswapRouterVerifier: recipient is not pool");

            emit RemovedLiquidity(pool, tokenA, tokenB, pair, numberOfLPTokens, block.timestamp);

            return (true, pair);
        }

        return (false, address(0));
    }

    /* ========== EVENTS ========== */

    event Swap(address pool, address srcAsset, address dstAsset, uint srcAmount, uint timestamp);
    event AddedLiquidity(address pool, address tokenA, address tokenB, address pair, uint amountADesired, uint amountBDesired, uint timestamp);
    event RemovedLiquidity(address pool, address tokenA, address tokenB, address pair, uint numberOfLPTokens, uint timestamp);
}