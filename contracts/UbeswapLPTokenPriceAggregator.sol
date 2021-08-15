pragma solidity >=0.5.0;

//Inheritance
import './interfaces/IPriceAggregator.sol';

//Interfaces
import './interfaces/IBaseUbeswapAdapter.sol';
import './interfaces/IAddressResolver.sol';
import './interfaces/IERC20.sol';

//Ubeswap interfaces
import './interfaces/Ubeswap/IUniswapV2Pair.sol';

//Libraries
import "./libraries/TradegenMath.sol";
import "./libraries/SafeMath.sol";

contract UbeswapLPTokenPriceAggregator is IPriceAggregator {
    using SafeMath for uint;

    IAddressResolver public ADDRESS_RESOLVER;

    constructor(IAddressResolver addressResolver) public {
        ADDRESS_RESOLVER = addressResolver;
    }

    /* ========== VIEWS ========== */

    function getUSDPrice(address pair) public view override returns (uint) {
        require(pair != address(0), "UbeswapLPTokenPriceAggregator: invalid asset address");

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        uint totalSupply = IUniswapV2Pair(pair).totalSupply();
        (uint reserve0, uint reserve1, ) = IUniswapV2Pair(pair).getReserves();

        reserve0 = uint(reserve0).mul(10**18).div(10**IERC20(token0).decimals()); // decimal = 18
        reserve1 = uint(reserve1).mul(10**18).div(10**IERC20(token1).decimals()); // decimal = 18

        uint r = TradegenMath.sqrt(reserve0.mul(reserve1)); // decimal = 18

        address baseUbeswapAdapterAddress = ADDRESS_RESOLVER.getContractAddress("BaseUbeswapAdapter");
        uint price0 = IBaseUbeswapAdapter(baseUbeswapAdapterAddress).getPrice(token0);
        uint price1 = IBaseUbeswapAdapter(baseUbeswapAdapterAddress).getPrice(token1);

        uint p = TradegenMath.sqrt(price0.mul(price1)); // decimal = 18

        return r.mul(p).mul(2).div(totalSupply);
    }
}