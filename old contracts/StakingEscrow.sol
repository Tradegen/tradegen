pragma solidity >=0.5.0;

//Libraries
import './libraries/SafeMath.sol';

// Inheritance
import "./Ownable.sol";

// Internal references
import "./interfaces/IERC20.sol";
import "./interfaces/IAddressResolver.sol";
import './interfaces/IStakingRewards.sol';

contract StakingEscrow is Ownable {
    using SafeMath for uint;

    IERC20 public TRADEGEN;
    address public stakingRewardsAddress;

    constructor(IAddressResolver _addressResolver) public Ownable() {
        address tradegenAddress = _addressResolver.getContractAddress("BaseTradegen");

        TRADEGEN = IERC20(tradegenAddress);
        stakingRewardsAddress = _addressResolver.getContractAddress("StakingRewards");
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function claimStakingRewards(address user, uint amount) public onlyStakingRewards {
        require(amount > 0, "No staking rewards to claim");
        require(TRADEGEN.balanceOf(address(this)) >= amount, "Not enough TGEN in escrow");
        
        TRADEGEN.transfer(user, amount);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyStakingRewards() {
        require(msg.sender == stakingRewardsAddress, "Only the StakingRewards contract can call this function");
        _;
    }
}