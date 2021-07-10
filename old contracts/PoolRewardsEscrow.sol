pragma solidity >=0.5.0;

//Libraries
import './libraries/SafeMath.sol';

// Inheritance
import "./Ownable.sol";
import './interfaces/IPoolRewardsEscrow.sol';

// Internal references
import "./interfaces/IERC20.sol";
import "./interfaces/IAddressResolver.sol";

contract PoolRewardsEscrow is Ownable, IPoolRewardsEscrow {
    using SafeMath for uint;

    IERC20 public TRADEGEN;
    address public poolRewardsAddress;

    constructor(IAddressResolver _addressResolver) public Ownable() {
        address tradegenAddress = _addressResolver.getContractAddress("BaseTradegen");

        TRADEGEN = IERC20(tradegenAddress);
        poolRewardsAddress = _addressResolver.getContractAddress("UserPoolFarm");
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function claimPoolRewards(address user, uint amount) public override onlyUserPoolFarm {
        require(amount > 0, "No pool rewards to claim");
        require(TRADEGEN.balanceOf(address(this)) >= amount, "Not enough TGEN in escrow");

        TRADEGEN.transfer(user, amount);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyUserPoolFarm() {
        require(msg.sender == poolRewardsAddress, "Only the UserPoolFarm contract can call this function");
        _;
    }
}