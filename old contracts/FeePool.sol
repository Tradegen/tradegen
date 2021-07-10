pragma solidity >=0.5.0;

//Libraries
import './libraries/SafeMath.sol';

// Inheritance
import "./Ownable.sol";
import './interfaces/IFeePool.sol';

// Internal references
import "./interfaces/IERC20.sol";
import "./interfaces/IAddressResolver.sol";

contract FeePool is Ownable, IFeePool {
    using SafeMath for uint;

    IAddressResolver public immutable ADDRESS_RESOLVER;

    mapping (address => uint) public availableTransactionFees;

    constructor(IAddressResolver _addressResolver) public Ownable() {
        ADDRESS_RESOLVER = _addressResolver;
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Returns the amount of transaction fees available for the user
    * @param account Address of the user
    * @return uint Amount of available transaction fees
    */
    function getAvailableTransactionFees(address account) external view override returns (uint) {
        require(account != address(0), "Invalid address");

        return availableTransactionFees[account];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Allow a user to claim any available transaction fees
    */
    function claimTransactionFees() external override {
        require(availableTransactionFees[msg.sender] > 0, "No transaction fees to claim");

        uint amount = availableTransactionFees[msg.sender];
        address baseTradegenAddress = ADDRESS_RESOLVER.getContractAddress("BaseTradegen");

        availableTransactionFees[msg.sender] = 0;
        IERC20(baseTradegenAddress).transfer(msg.sender, amount);

        emit ClaimedTransactionFees(msg.sender, amount, block.timestamp);
    }

    /**
    * @notice Adds transaction fees to the strategy's developer
    * @notice Function gets called by StrategyProxy whenever users invest in the strategy or buys a position from the marketplace
    * @param account Address of the user
    * @param amount Amount of TGEN to add
    */
    function addTransactionFees(address account, uint amount) public override onlyStrategyProxy {
        require(amount > 0, "Amount must be greater than 0");
        require(account != address(0), "Invalid address");

        availableTransactionFees[account] = availableTransactionFees[account].add(amount);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyStrategyProxy() {
        address strategyProxyAddress = ADDRESS_RESOLVER.getContractAddress("StrategyProxy");
        
        require(msg.sender == strategyProxyAddress, "Only the StrategyProxy contract can call this function");
        _;
    }

    /* ========== EVENTS ========== */

    event ClaimedTransactionFees(address user, uint amount, uint timestamp);
}