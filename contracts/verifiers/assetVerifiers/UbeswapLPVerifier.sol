// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

//Libraries
import "../../libraries/TxDataUtils.sol";
import "../../openzeppelin-solidity/SafeMath.sol";

//Inheritance
import "./ERC20Verifier.sol";
import "../../Ownable.sol";
import "../../interfaces/ILPVerifier.sol";

//Internal references
import "../../interfaces/IAddressResolver.sol";
import "../../interfaces/IAssetHandler.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/IBaseUbeswapAdapter.sol";
import "../../interfaces/Ubeswap/IStakingRewards.sol";

contract UbeswapLPVerifier is ERC20Verifier, Ownable, ILPVerifier {
    using SafeMath for uint;

    IAddressResolver public ADDRESS_RESOLVER;

    mapping (address => address) public ubeswapFarms;
    mapping (address => address) public stakingTokens; //farm => pair
    mapping (address => address) public rewardTokens; //farm => reward token

    constructor(IAddressResolver addressResolver) Ownable() {
        ADDRESS_RESOLVER = addressResolver;
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Creates transaction data for withdrawing tokens
    * @param pool Address of the pool
    * @param asset Address of the asset
    * @param portion Portion of the pool's balance in the asset
    * @return (address, uint, MultiTransaction[]) Withdrawn asset, amount of asset withdrawn, and transactions used to execute the withdrawal
    */
    function prepareWithdrawal(address pool, address asset, uint portion) external view override returns (address, uint, MultiTransaction[] memory transactions) {
        require(pool != address(0), "UbeswapLPVerifier: invalid pool address");
        require(asset != address(0), "UbeswapLPVerifier: invalid asset address");
        require(portion > 0, "UbeswapLPVerifier: portion must be greater than 0");

        uint poolBalance = IERC20(asset).balanceOf(pool);
        uint withdrawBalance = poolBalance.mul(portion).div(10**18);
        uint stakedBalance = IStakingRewards(ubeswapFarms[asset]).balanceOf(pool);

        //Prepare transaction data
        if (stakedBalance > 0)
        {
            uint stakedWithdrawBalance = stakedBalance.mul(portion).div(10**18);
            transactions = new MultiTransaction[](1);
            transactions[0].to = ubeswapFarms[asset];
            transactions[0].txData = abi.encodeWithSelector(bytes4(keccak256("withdraw(uint256)")), stakedWithdrawBalance);
        }

        return (asset, withdrawBalance, transactions);
    }

    /**
    * @dev Returns the pool's balance in the asset
    * @notice May included staked balance in external contracts
    * @param pool Address of the pool
    * @param asset Address of the asset
    * @return uint Pool's balance in the asset
    */
    function getBalance(address pool, address asset) public view override returns (uint) {
        require(pool != address(0), "UbeswapLPVerifier: invalid pool address");
        require(asset != address(0), "UbeswapLPVerifier: invalid asset address");

        uint poolBalance = IERC20(asset).balanceOf(pool);
        uint stakedBalance = IStakingRewards(ubeswapFarms[asset]).balanceOf(pool);

        return poolBalance.add(stakedBalance);
    }

    /**
    * @dev Given the address of a farm, returns the farm's staking token and reward token
    * @param farmAddress Address of the farm
    * @return (address, address) Address of the staking token and reward token
    */
    function getFarmTokens(address farmAddress) external view override returns (address, address) {
        require(farmAddress != address(0), "UbeswapLPVerifier: invalid farm address");

        return (stakingTokens[farmAddress], rewardTokens[farmAddress]);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @dev Updates the farm address for the pair
    * @notice Meant to be called by contract owner
    * @param pair Address of pair on Ubeswap
    * @param farmAddress Address of farm on Ubeswap
    * @param rewardToken Address of token paid to stakers
    */
    function setFarmAddress(address pair, address farmAddress, address rewardToken) external onlyOwner {
        require(pair != address(0), "UbeswapLPVerifier: invalid pair address");
        require(farmAddress != address(0), "UbeswapLPVerifier: invalid farm address");
        require(rewardToken != address(0), "UbeswapLPVerifier: invalid reward token");

        ubeswapFarms[pair] = farmAddress;
        stakingTokens[farmAddress] = pair;
        rewardTokens[farmAddress] = rewardToken;

        emit UpdatedFarmAddress(pair, farmAddress, rewardToken, block.timestamp);
    }

    /* ========== EVENTS ========== */

    event InitializedFarms(uint numberOfFarms, address[] pairs, uint timestamp);
    event UpdatedFarmAddress(address pair, address farmAddress, address rewardToken, uint timestamp);
}