pragma solidity >=0.5.0;

//Libraries
import './libraries/SafeMath.sol';

// Inheritance
import "./Ownable.sol";
import './interfaces/IStrategyVotingEscrow.sol';

// Internal references
import "./interfaces/IERC20.sol";
import "./interfaces/IAddressResolver.sol";

contract StrategyVotingEscrow is Ownable, IStrategyVotingEscrow {
    using SafeMath for uint;

    IERC20 public TRADEGEN;
    address public strategyVotingAddress;

    constructor(IAddressResolver _addressResolver) public Ownable() {
        address tradegenAddress = _addressResolver.getContractAddress("BaseTradegen");

        TRADEGEN = IERC20(tradegenAddress);
        strategyVotingAddress = _addressResolver.getContractAddress("StrategyApproval");
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function claimRewards(address user, uint amount) public override onlyStrategyApproval {
        require(amount > 0, "No strategy voting rewards to claim");
        require(TRADEGEN.balanceOf(address(this)) >= amount, "Not enough TGEN in escrow");

        TRADEGEN.transfer(user, amount);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyStrategyApproval() {
        require(msg.sender == strategyVotingAddress, "Only the StrategyApproval contract can call this function");
        _;
    }
}