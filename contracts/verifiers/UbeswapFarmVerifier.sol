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
import "../interfaces/ILPVerifier.sol";
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
    * @return (uint, address) Whether the transaction is valid and the received asset
    */
    function verify(address addressResolver, address pool, address to, bytes calldata data) external override returns (bool, address) {
        bytes4 method = getMethod(data);

        address assetHandlerAddress = IAddressResolver(addressResolver).getContractAddress("AssetHandler");
        address ubeswapLPVerifierAddress = IAddressResolver(addressResolver).assetVerifiers(2);

        //Get assets 
        (address pair, address rewardToken) = ILPVerifier(ubeswapLPVerifierAddress).getFarmTokens(to);

        if (method == bytes4(keccak256("stake(uint256)")))
        {
            //Parse transaction data
            uint numberOfLPTokens = uint(getInput(data, 0));

            //Check if assets are supported
            require(IAssetHandler(assetHandlerAddress).isValidAsset(rewardToken), "UbeswapFarmVerifier: unsupported reward token");
            require(IAssetHandler(assetHandlerAddress).isValidAsset(pair), "UbeswapFarmVerifier: unsupported liquidity pair");

            emit Staked(pool, to, numberOfLPTokens, block.timestamp);

            return (true, rewardToken);
        }
        else if (method == bytes4(keccak256("withdraw(uint256)")))
        {
            //Parse transaction data
            uint numberOfLPTokens = uint(getInput(data, 0));

            //Check if assets are supported
            require(IAssetHandler(assetHandlerAddress).isValidAsset(pair), "UbeswapFarmVerifier: unsupported liquidity pair");

            emit Unstaked(pool, to, numberOfLPTokens, block.timestamp);

            return (true, pair);
        }
        else if (method == bytes4(keccak256("getReward()")))
        {
            //Check if assets are supported
            require(IAssetHandler(assetHandlerAddress).isValidAsset(rewardToken), "UbeswapFarmVerifier: unsupported reward token");

            emit ClaimedReward(pool, to, block.timestamp);

            return (true, rewardToken);
        }
        else if (method == bytes4(keccak256("exit()")))
        {
            uint numberOfLPTokens = IStakingRewards(to).balanceOf(pool);

            //Check if assets are supported
            require(IAssetHandler(assetHandlerAddress).isValidAsset(rewardToken), "UbeswapFarmVerifier: unsupported reward token");
            require(IAssetHandler(assetHandlerAddress).isValidAsset(pair), "UbeswapFarmVerifier: unsupported liquidity pair");

            emit Unstaked(pool, to, numberOfLPTokens, block.timestamp);
            emit ClaimedReward(pool, to, block.timestamp);

            return (true, rewardToken);
        }

        return (false, address(0));
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed pool, address indexed farm, uint numberOfLPTokens, uint timestamp);
    event Unstaked(address indexed pool, address indexed farm, uint numberOfLPTokens, uint timestamp);
    event ClaimedReward(address indexed pool, address indexed farm, uint timestamp);
}