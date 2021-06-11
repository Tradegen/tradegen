pragma solidity >=0.5.0;

import '../interfaces/IUniswapV2Router02.sol';
import './interfaces/IBaseUbeswapAdapter.sol';

import '../libraries/SafeMath.sol';

contract BaseUbeswapAdapter is IBaseUbeswapAdapter {
    using SafeMath for uint;

    // Max slippage percent allowed
    uint public constant MAX_SLIPPAGE_PERCENT = 10; //10% slippage

    IUniswapV2Router02 public immutable UBESWAP_ROUTER;

    constructor(IUniswapV2Router02 ubeswapRouter) public {
        UBESWAP_ROUTER = ubeswapRouter;
    }

    /**
    * @dev Given an input asset amount, returns the maximum output amount of the other asset and the prices
    * @param amountIn Amount of reserveIn
    * @param reserveIn Address of the asset to be swap from
    * @param reserveOut Address of the asset to be swap to
    * @return uint Amount out of the reserveOut
    * @return uint The price of out amount denominated in the reserveIn currency (18 decimals)
    * @return uint In amount of reserveIn value denominated in USD (8 decimals)
    * @return uint Out amount of reserveOut value denominated in USD (8 decimals)
    */
    function getAmountsOut(uint amountIn, address reserveIn, address reserveOut) external view override returns (uint, uint, uint, uint, address[] memory) {
        AmountCalc memory results = _getAmountsOutData(reserveIn, reserveOut, amountIn);

        return (results.calculatedAmount, results.relativePrice, results.amountInUsd, results.amountOutUsd, results.path);
    }

    /**
    * @dev Returns the minimum input asset amount required to buy the given output asset amount and the prices
    * @param amountOut Amount of reserveOut
    * @param reserveIn Address of the asset to be swap from
    * @param reserveOut Address of the asset to be swap to
    * @return uint Amount in of the reserveIn
    * @return uint The price of in amount denominated in the reserveOut currency (18 decimals)
    * @return uint In amount of reserveIn value denominated in USD (8 decimals)
    * @return uint Out amount of reserveOut value denominated in USD (8 decimals)
    */
    function getAmountsIn(uint amountOut, address reserveIn, address reserveOut) external view override returns (uint, uint, uint, uint, address[] memory) {
        AmountCalc memory results = _getAmountsInData(reserveIn, reserveOut, amountOut);

        return (results.calculatedAmount, results.relativePrice, results.amountInUsd, results.amountOutUsd, results.path);
    }
}