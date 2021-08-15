pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

//Libraries
import "../../libraries/TxDataUtils.sol";
import "../../libraries/SafeMath.sol";

//Inheritance
import "./ERC20Verifier.sol";
import "../../Ownable.sol";

//Internal references
import "../../interfaces/IAddressResolver.sol";
import "../../interfaces/IAssetHandler.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/IBaseUbeswapAdapter.sol";
import "../../interfaces/Ubeswap/IStakingRewards.sol";

contract UbeswapLPVerifier is ERC20Verifier, Ownable {
    using SafeMath for uint;

    IAddressResolver public ADDRESS_RESOLVER;

    mapping (address => address) public ubeswapFarms;

    constructor(IAddressResolver addressResolver) public Ownable() {
        ADDRESS_RESOLVER = addressResolver;
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Creates transaction data for withdrawing tokens
    * @param pool Address of the pool
    * @param asset Address of the asset
    * @param portion Portion of the pool's balance in the asset
    * @param to Recipient's address
    * @return (address, uint, MultiTransaction[]) Withdrawn asset, amount of asset withdrawn, and transactions used to execute the withdrawal
    */
    function prepareWithdrawal(address pool, address asset, uint portion, address to) public view override returns (address, uint, MultiTransaction[] memory transactions) {
        require(pool != address(0), "UbeswapLPVerifier: invalid pool address");
        require(asset != address(0), "UbeswapLPVerifier: invalid asset address");
        require(to != address(0), "UbeswapLPVerifier: invalid address");
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

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @dev Initializes the contract's available Ubeswap farms
    * @notice Meant to be called by contract owner
    */
    function initializeFarms() external onlyOwner {
        address baseUbeswapAdapterAddress = ADDRESS_RESOLVER.getContractAddress("BaseUbeswapAdapter");

        address[] memory availableFarms = IBaseUbeswapAdapter(baseUbeswapAdapterAddress).getAvailableUbeswapFarms();
        for (uint i = 0; i < availableFarms.length; i++)
        {
            address pair = IStakingRewards(availableFarms[i]).stakingToken();
            ubeswapFarms[pair] = availableFarms[i];
        }

        emit InitializedFarms(availableFarms.length, block.timestamp);
    }

    /**
    * @dev Updates the farm address for the pair
    * @notice Meant to be called by contract owner
    * @param pair Address of pair on Ubeswap
    * @param farmAddress Address of farm on Ubeswap
    */
    function setFarmAddress(address pair, address farmAddress) external onlyOwner {
        require(pair != address(0), "UbeswapLPVerifier: invalid pair address");
        require(farmAddress != address(0), "UbeswapLPVerifier: invalid farm address");
        
        address baseUbeswapAdapterAddress = ADDRESS_RESOLVER.getContractAddress("BaseUbeswapAdapter");
        require(pair == IBaseUbeswapAdapter(baseUbeswapAdapterAddress).checkIfFarmExists(farmAddress), "UbeswapLPVerifier: invalid farm for pair");

        ubeswapFarms[pair] = farmAddress;

        emit UpdatedFarmAddress(pair, farmAddress, block.timestamp);
    }

    /* ========== EVENTS ========== */

    event InitializedFarms(uint numberOfFarms, uint timestamp);
    event UpdatedFarmAddress(address pair, address farmAddress, uint timestamp);
}