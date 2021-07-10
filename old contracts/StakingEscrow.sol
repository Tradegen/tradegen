pragma solidity >=0.5.0;

//Libraries
import './libraries/SafeMath.sol';

// Inheritance
import "./Ownable.sol";
import './interfaces/IStakingEscrow.sol';

// Internal references
import "./interfaces/IERC20.sol";
import "./interfaces/IAddressResolver.sol";

contract StakingEscrow is Ownable, IStakingEscrow {
    using SafeMath for uint;

    IAddressResolver public immutable ADDRESS_RESOLVER;

    constructor(IAddressResolver _addressResolver) public Ownable() {
        ADDRESS_RESOLVER = _addressResolver;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function claimStakingRewards(address user, uint amount) public override onlyStakingRewards {
        address baseTradegenAddress = ADDRESS_RESOLVER.getContractAddress("BaseTradegen");

        require(amount > 0, "No staking rewards to claim");
        require(IERC20(baseTradegenAddress).balanceOf(address(this)) >= amount, "Not enough TGEN in escrow");

        IERC20(baseTradegenAddress).transfer(user, amount);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyStakingRewards() {
        address stakingRewardsAddress = ADDRESS_RESOLVER.getContractAddress("StakingRewards");
        
        require(msg.sender == stakingRewardsAddress, "Only the StakingRewards contract can call this function");
        _;
    }
}