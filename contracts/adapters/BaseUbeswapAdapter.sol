pragma solidity >=0.5.0;

import '../interfaces/IUniswapV2Router02.sol';
import '../interfaces/IERC20.sol';
import './interfaces/IBaseUbeswapAdapter.sol';

import '../libraries/SafeMath.sol';

import '../AddressResolver.sol';
import '../Settings.sol';

contract BaseUbeswapAdapter is IBaseUbeswapAdapter, AddressResolver {
    using SafeMath for uint;

    // Max slippage percent allowed
    uint public constant override MAX_SLIPPAGE_PERCENT = 10; //10% slippage

    IUniswapV2Router02 public immutable override UBESWAP_ROUTER;

    constructor(IUniswapV2Router02 ubeswapRouter) public {
        UBESWAP_ROUTER = ubeswapRouter;
        _setBaseUbeswapAdapterAddress(address(this));
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Given an input asset address, returns the price of the asset in cUSD
    * @param currencyKey Address of the asset
    * @return uint Price of the asset
    */
    function getPrice(address currencyKey) public view override returns(uint) {
        require(currencyKey != address(0), "Invalid currency key");
        require(Settings(getSettingsAddress()).checkIfCurrencyIsAvailable(currencyKey), "Currency is not available");

        address stableCoinAddress = Settings(getSettingsAddress()).getStableCurrencyAddress();
        address[] memory path = new address[](2);
        path[0] = currencyKey;
        path[1] = stableCoinAddress;
        uint[] memory amounts = UBESWAP_ROUTER.getAmountsOut(_getDecimals(currencyKey), path); // 1 token -> cUSD

        return amounts[1];
    }

    /**
    * @dev Given an input asset amount, returns the maximum output amount of the other asset
    * @param numberOfTokens Number of tokens
    * @param currencyKeyIn Address of the asset to be swap from
    * @param currencyKeyOut Address of the asset to be swap to
    * @return uint Amount out of the asset
    */
    function getAmountsOut(uint numberOfTokens, address currencyKeyIn, address currencyKeyOut) public view override returns (uint) {
        require(currencyKeyIn != address(0), "Invalid currency key in");
        require(currencyKeyOut != address(0), "Invalid currency key out");
        require(Settings(getSettingsAddress()).checkIfCurrencyIsAvailable(currencyKeyIn), "Currency is not available");
        require(Settings(getSettingsAddress()).checkIfCurrencyIsAvailable(currencyKeyOut), "Currency is not available");
        require(numberOfTokens > 0, "Number of tokens must be greater than 0");

        address[] memory path = new address[](2);
        path[0] = currencyKeyIn;
        path[1] = currencyKeyOut;
        uint[] memory amounts = UBESWAP_ROUTER.getAmountsOut(numberOfTokens, path);

        return amounts[1];
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @dev Swaps an exact `amountToSwap` of an asset to another; meant to be called from a user pool
    * @param assetToSwapFrom Origin asset
    * @param assetToSwapTo Destination asset
    * @param amountToSwap Exact amount of `assetToSwapFrom` to be swapped
    * @param minAmountOut the min amount of `assetToSwapTo` to be received from the swap
    * @return the number of tokens received
    */
    function swapFromPool(address assetToSwapFrom, address assetToSwapTo, uint amountToSwap, uint minAmountOut) external override isValidPoolAddress(msg.sender) returns (uint) {
        return _swapExactTokensForTokens(msg.sender, assetToSwapFrom, assetToSwapTo, amountToSwap, minAmountOut);
    }

    /**
    * @dev Swaps an exact `amountToSwap` of an asset to another; meant to be called from a trading bot
    * @param assetToSwapFrom Origin asset
    * @param assetToSwapTo Destination asset
    * @param amountToSwap Exact amount of `assetToSwapFrom` to be swapped
    * @param minAmountOut the min amount of `assetToSwapTo` to be received from the swap
    * @return the number of tokens received
    */
    function swapFromBot(address assetToSwapFrom, address assetToSwapTo, uint amountToSwap, uint minAmountOut) external override onlyTradingBot(msg.sender) returns (uint) {
        return _swapExactTokensForTokens(msg.sender, assetToSwapFrom, assetToSwapTo, amountToSwap, minAmountOut);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
    * @dev Swaps an exact `amountToSwap` of an asset to another
    * @param addressToSwapFrom the pool or bot that is making the swap
    * @param assetToSwapFrom Origin asset
    * @param assetToSwapTo Destination asset
    * @param amountToSwap Exact amount of `assetToSwapFrom` to be swapped
    * @param minAmountOut the min amount of `assetToSwapTo` to be received from the swap
    * @return the amount of tokens received
    */
    function _swapExactTokensForTokens(address addressToSwapFrom, address assetToSwapFrom, address assetToSwapTo, uint amountToSwap, uint minAmountOut) internal returns (uint) {
        uint fromAssetDecimals = _getDecimals(assetToSwapFrom);
        uint toAssetDecimals = _getDecimals(assetToSwapTo);

        uint fromAssetPrice = getPrice(assetToSwapFrom); //cUSD price of asset
        uint toAssetPrice = getPrice(assetToSwapTo); //cUSD price of asset

        uint expectedMinAmountOut = amountToSwap.mul(fromAssetPrice.mul(10**toAssetDecimals)).mul(MAX_SLIPPAGE_PERCENT).div(toAssetPrice.mul(10**fromAssetDecimals)).div(100);

        require(expectedMinAmountOut < minAmountOut, 'minAmountOut exceed max slippage');

        // Approves the transfer for the swap. Approves for 0 first to comply with tokens that implement the anti frontrunning approval fix.
        IERC20(assetToSwapFrom).approve(address(UBESWAP_ROUTER), 0);
        IERC20(assetToSwapFrom).approve(address(UBESWAP_ROUTER), amountToSwap);

        address[] memory path;
        path = new address[](2);
        path[0] = assetToSwapFrom;
        path[1] = assetToSwapTo;

        uint[] memory amounts = UBESWAP_ROUTER.swapExactTokensForTokens(amountToSwap, minAmountOut, path, addressToSwapFrom, block.timestamp);

        emit Swapped(assetToSwapFrom, assetToSwapTo, amounts[0], amounts[amounts.length - 1]);

        return amounts[amounts.length - 1];
    }

    /**
    * @dev Get the decimals of an asset
    * @return number of decimals of the asset
    */
    function _getDecimals(address asset) internal view returns (uint) {
        return IERC20(asset).decimals();
    }
}