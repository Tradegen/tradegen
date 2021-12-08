// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

//Interfaces
import './interfaces/Ubeswap/IUniswapV2Router02.sol';
import './interfaces/IERC20.sol';
import './interfaces/IAssetHandler.sol';
import './interfaces/IAddressResolver.sol';
import './interfaces/IUbeswapPathManager.sol';
import './interfaces/Ubeswap/IUbeswapPoolManager.sol';
import './interfaces/Ubeswap/IStakingRewards.sol';
import './interfaces/Ubeswap/IUniswapV2Factory.sol';
import './interfaces/Ubeswap/IStakingRewards.sol';

//Inheritance
import './interfaces/IBaseUbeswapAdapter.sol';

//Libraries
import "./openzeppelin-solidity/SafeMath.sol";

contract BaseUbeswapAdapter is IBaseUbeswapAdapter {
    using SafeMath for uint;

    // Max slippage percent allowed
    uint public constant override MAX_SLIPPAGE_PERCENT = 10; //10% slippage

    IAddressResolver public immutable ADDRESS_RESOLVER;

    constructor(IAddressResolver addressResolver) {
        ADDRESS_RESOLVER = addressResolver;
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Given an input asset address, returns the price of the asset in USD
    * @param currencyKey Address of the asset
    * @return uint Price of the asset
    */
    function getPrice(address currencyKey) external view override returns(uint) {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address ubeswapRouterAddress = ADDRESS_RESOLVER.getContractAddress("UbeswapRouter");
        address stableCoinAddress = IAssetHandler(assetHandlerAddress).getStableCoinAddress();

        //Check if currency key is stablecoin
        if (currencyKey == stableCoinAddress)
        {
            return 10 ** _getDecimals(currencyKey);
        }

        require(currencyKey != address(0), "Invalid currency key");
        require(IAssetHandler(assetHandlerAddress).isValidAsset(currencyKey), "BaseUbeswapAdapter: Currency is not available");

        address ubeswapPathManagerAddress = ADDRESS_RESOLVER.getContractAddress("UbeswapPathManager");
        address[] memory path = IUbeswapPathManager(ubeswapPathManagerAddress).getPath(currencyKey, stableCoinAddress);
        uint[] memory amounts = IUniswapV2Router02(ubeswapRouterAddress).getAmountsOut(10 ** _getDecimals(currencyKey), path); // 1 token -> USD

        return amounts[amounts.length - 1];
    }

    /**
    * @dev Given an input asset amount, returns the maximum output amount of the other asset
    * @notice Assumes numberOfTokens is multiplied by currency's decimals before function call
    * @param numberOfTokens Number of tokens
    * @param currencyKeyIn Address of the asset to be swap from
    * @param currencyKeyOut Address of the asset to be swap to
    * @return uint Amount out of the asset
    */
    function getAmountsOut(uint numberOfTokens, address currencyKeyIn, address currencyKeyOut) external view override returns (uint) {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address ubeswapRouterAddress = ADDRESS_RESOLVER.getContractAddress("UbeswapRouter");
        address stableCoinAddress = IAssetHandler(assetHandlerAddress).getStableCoinAddress();

        require(currencyKeyIn != address(0), "Invalid currency key in");
        require(currencyKeyOut != address(0), "Invalid currency key out");
        require(IAssetHandler(assetHandlerAddress).isValidAsset(currencyKeyIn) || currencyKeyIn == stableCoinAddress, "BaseUbeswapAdapter: CurrencyKeyIn is not available");
        require(IAssetHandler(assetHandlerAddress).isValidAsset(currencyKeyOut) || currencyKeyOut == stableCoinAddress, "BaseUbeswapAdapter: CurrencyKeyOut is not available");
        require(numberOfTokens > 0, "Number of tokens must be greater than 0");

        address ubeswapPathManagerAddress = ADDRESS_RESOLVER.getContractAddress("UbeswapPathManager");
        address[] memory path = IUbeswapPathManager(ubeswapPathManagerAddress).getPath(currencyKeyIn, currencyKeyOut);
        uint[] memory amounts = IUniswapV2Router02(ubeswapRouterAddress).getAmountsOut(numberOfTokens, path);

        return amounts[1];
    }

    /**
    * @dev Given the target output asset amount, returns the amount of input asset needed
    * @param numberOfTokens Target amount of output asset
    * @param currencyKeyIn Address of the asset to be swap from
    * @param currencyKeyOut Address of the asset to be swap to
    * @return uint Amount out input asset needed
    */
    function getAmountsIn(uint numberOfTokens, address currencyKeyIn, address currencyKeyOut) external view override returns (uint) {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address ubeswapRouterAddress = ADDRESS_RESOLVER.getContractAddress("UbeswapRouter");
        address stableCoinAddress = IAssetHandler(assetHandlerAddress).getStableCoinAddress();

        require(currencyKeyIn != address(0), "Invalid currency key in");
        require(currencyKeyOut != address(0), "Invalid currency key out");
        require(IAssetHandler(assetHandlerAddress).isValidAsset(currencyKeyIn) || currencyKeyIn == stableCoinAddress, "BaseUbeswapAdapter: CurrencyKeyIn is not available");
        require(IAssetHandler(assetHandlerAddress).isValidAsset(currencyKeyOut) || currencyKeyOut == stableCoinAddress, "BaseUbeswapAdapter: CurrencyKeyOut is not available");
        require(numberOfTokens > 0, "Number of tokens must be greater than 0");

        address ubeswapPathManagerAddress = ADDRESS_RESOLVER.getContractAddress("UbeswapPathManager");
        address[] memory path = IUbeswapPathManager(ubeswapPathManagerAddress).getPath(currencyKeyIn, currencyKeyOut);
        uint[] memory amounts = IUniswapV2Router02(ubeswapRouterAddress).getAmountsIn(numberOfTokens, path);

        return amounts[1];
    }

    /**
    * @dev Returns the address of each available farm on Ubeswap
    * @return address[] memory The farm address for each available farm
    */
    function getAvailableUbeswapFarms() external view override returns (address[] memory) {
        address ubeswapPoolManagerAddress = ADDRESS_RESOLVER.getContractAddress("UbeswapPoolManager");

        uint numberOfAvailableFarms = IUbeswapPoolManager(ubeswapPoolManagerAddress).poolsCount();
        address[] memory poolAddresses = new address[](numberOfAvailableFarms);
        address[] memory farmAddresses = new address[](numberOfAvailableFarms);

        //Get supported LP tokens
        for (uint i = 0; i < numberOfAvailableFarms; i++)
        {
            poolAddresses[i] = IUbeswapPoolManager(ubeswapPoolManagerAddress).poolsByIndex(i);
        }

        //Get supported farms
        for (uint i = 0; i < numberOfAvailableFarms; i++)
        {
            IUbeswapPoolManager.PoolInfo memory farm = IUbeswapPoolManager(ubeswapPoolManagerAddress).pools(poolAddresses[i]);
            farmAddresses[i] = farm.poolAddress;
        }

        return farmAddresses;
    }

    /**
    * @dev Checks whether the given liquidity pair has a farm on Ubeswap
    * @param pair Address of the liquidity pair
    * @return bool Whether the pair has a farm
    */
    function checkIfLPTokenHasFarm(address pair) external view override returns (bool) {
        require(pair != address(0), "BaseUbeswapAdapter: invalid pair address");

        address ubeswapPoolManagerAddress = ADDRESS_RESOLVER.getContractAddress("UbeswapPoolManager");
        IUbeswapPoolManager.PoolInfo memory ubeswapFarm = IUbeswapPoolManager(ubeswapPoolManagerAddress).pools(pair);

        return (ubeswapFarm.poolAddress != address(0));
    }

    /**
    * @dev Returns the address of a token pair
    * @param tokenA First token in pair
    * @param tokenB Second token in pair
    * @return address The pair's address
    */
    function getPair(address tokenA, address tokenB) public view override returns (address) {
        require(tokenA != address(0), "BaseUbeswapAdapter: invalid address for tokenA");
        require(tokenB != address(0), "BaseUbeswapAdapter: invalid address for tokenB");

        address uniswapV2FactoryAddress = ADDRESS_RESOLVER.getContractAddress("UniswapV2Factory");

        return IUniswapV2Factory(uniswapV2FactoryAddress).getPair(tokenA, tokenB);
    }

    /**
    * @dev Returns the amount of UBE rewards available for the pool in the given farm
    * @param poolAddress Address of the pool
    * @param farmAddress Address of the farm on Ubeswap
    * @return uint Amount of UBE available
    */
    function getAvailableRewards(address poolAddress, address farmAddress) external view override returns (uint) {
        require(poolAddress != address(0), "BaseUbeswapAdapter: invalid pool address");

        return IStakingRewards(farmAddress).earned(poolAddress);
    }

    /**
    * @dev Calculates the amount of tokens in a pair
    * @param tokenA First token in pair
    * @param tokenB Second token in pair
    * @param numberOfLPTokens Number of LP tokens for the given pair
    * @return (uint, uint) The number of tokens for tokenA and tokenB
    */
    function getTokenAmountsFromPair(address tokenA, address tokenB, uint numberOfLPTokens) external view override returns (uint, uint) {
        address pair = getPair(tokenA, tokenB);
        require(pair != address(0), "BaseUbeswapAdapter: invalid address for pair");

        uint pairBalanceTokenA = IERC20(tokenA).balanceOf(pair);
        uint pairBalanceTokenB = IERC20(tokenB).balanceOf(pair);
        uint totalSupply = IERC20(pair).totalSupply();

        uint amountA = pairBalanceTokenA.mul(numberOfLPTokens).div(totalSupply);
        uint amountB = pairBalanceTokenB.mul(numberOfLPTokens).div(totalSupply);

        return (amountA, amountB);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
    * @dev Get the decimals of an asset
    * @return number of decimals of the asset
    */
    function _getDecimals(address asset) internal view returns (uint) {
        return IERC20(asset).decimals();
    }
}