pragma solidity >=0.5.0;

//Libraries
import "../libraries/TxDataUtils.sol";
import "../libraries/SafeMath.sol";

//Inheritance
import "../interfaces/IVerifier.sol";

//Interfaces
import "../interfaces/IAddressResolver.sol";
import "../interfaces/IAssetHandler.sol";
import "../interfaces/Ubeswap/IStakingRewards.sol";
import "../interfaces/Ubeswap/IUniswapV2Pair.sol";

contract UbeswapFarmVerifier is TxDataUtils, IVerifier {
    using SafeMath for uint;

    /**
    * @dev Parses the transaction data to make sure the transaction is valid
    * @param addressResolver Address of AddressResolver contract
    * @param pool Address of the pool
    * @param to External contract address
    * @param data Transaction call data
    * @return uint Type of the asset
    */
    function verify(address addressResolver, address pool, address to, bytes calldata data) public override returns (bool) {
        bytes4 method = getMethod(data);

        address assetHandlerAddress = IAddressResolver(addressResolver).getContractAddress("AssetHandler");

        if (method == bytes4(keccak256("stake(uint)")))
        {
            //Parse transaction data
            uint numberOfLPTokens = uint(getInput(data, 0));

            //Get assets 
            address pair = IStakingRewards(to).stakingToken();
            address rewardToken = IStakingRewards(to).rewardsToken();

            //Check if assets are supported
            require(IAssetHandler(assetHandlerAddress).isValidAsset(rewardToken), "UbeswapFarmVerifier: unsupported reward token");
            require(IAssetHandler(assetHandlerAddress).isValidAsset(pair), "UbeswapFarmVerifier: unsupported liquidity pair");

            emit Staked(pool, to, numberOfLPTokens, block.timestamp);

            return true;
        }
        else if (method == bytes4(keccak256("withdraw(uint)")))
        {
            //Parse transaction data
            uint numberOfLPTokens = uint(getInput(data, 0));

            //Get assets
            address pair = IStakingRewards(to).stakingToken();

            //Check if assets are supported
            require(IAssetHandler(assetHandlerAddress).isValidAsset(pair), "UbeswapFarmVerifier: unsupported liquidity pair");

            emit Unstaked(pool, to, numberOfLPTokens, block.timestamp);

            return true;
        }
        else if (method == bytes4(keccak256("getReward()")))
        {
            //Get assets
            address rewardToken = IStakingRewards(to).rewardsToken();

            //Check if assets are supported
            require(IAssetHandler(assetHandlerAddress).isValidAsset(rewardToken), "UbeswapFarmVerifier: unsupported reward token");

            emit ClaimedReward(pool, to, block.timestamp);

            return true;
        }
        else if (method == bytes4(keccak256("exit()")))
        {
            //Get assets
            address pair = IStakingRewards(to).stakingToken();
            address rewardToken = IStakingRewards(to).rewardsToken();

            uint numberOfLPTokens = IStakingRewards(to).balanceOf(pool);

            //Check if assets are supported
            require(IAssetHandler(assetHandlerAddress).isValidAsset(rewardToken), "UbeswapFarmVerifier: unsupported reward token");
            require(IAssetHandler(assetHandlerAddress).isValidAsset(pair), "UbeswapFarmVerifier: unsupported liquidity pair");

            emit Unstaked(pool, to, numberOfLPTokens, block.timestamp);
            emit ClaimedReward(pool, to, block.timestamp);

            return true;
        }

        return false;
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed pool, address indexed farm, uint numberOfLPTokens, uint timestamp);
    event Unstaked(address indexed pool, address indexed farm, uint numberOfLPTokens, uint timestamp);
    event ClaimedReward(address indexed pool, address indexed farm, uint timestamp);
}