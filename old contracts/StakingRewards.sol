pragma solidity >=0.5.0;

//Libraries
import './libraries/SafeMath.sol';

//Interfaces
import './interfaces/IERC20.sol';
import './interfaces/IAddressResolver.sol';
import './interfaces/ISettings.sol';
import './interfaces/IStakingEscrow.sol';
import './interfaces/IStrategyVotingEscrow.sol';

//Inheritance
import './interfaces/IStakingRewards.sol';

contract StakingRewards is IStakingRewards {
    using SafeMath for uint;

    IAddressResolver public immutable ADDRESS_RESOLVER;
    address public strategyApprovalAddress;

    uint private _totalSupply;
    mapping(address => uint) private _balances;
    mapping(address => State) private _userToState;

    constructor(IAddressResolver addressResolver) public {
        ADDRESS_RESOLVER = addressResolver;
        strategyApprovalAddress = addressResolver.getContractAddress("StrategyApproval");
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Returns the total amount of TGEN staked
    * @return uint The amount of TGEN staked in the protocol
    */
    function totalSupply() external view override returns (uint) {
        return _totalSupply;
    }

    /**
    * @dev Returns the amount of TGEN the user has staked
    * @param account Address of the user
    * @return uint The amount of TGEN the user has staked
    */
    function balanceOf(address account) public view override returns (uint) {
        return _balances[account];
    }

    /**
    * @dev Wrapper for internal calculateAvailableYield() function 
    * @return uint The user's available yield
    */
    function getAvailableYield() external view override returns (uint) {
        return _calculateAvailableYield(msg.sender);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @dev Stakes TGEN in the protocol
    * @param amount Amount of TGEN to stake
    */
    function stake(uint amount) external override {
        require(amount > 0, "Cannot stake 0");

        _userToState[msg.sender].timestamp = uint32(block.timestamp);
        _userToState[msg.sender].leftoverYield = uint224(_calculateAvailableYield(msg.sender));
        
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);

        //Transfer TGEN from user to StakingRewards contract; call TradegenERC20.approve() on frontend before sending transaction
        IERC20(ADDRESS_RESOLVER.getContractAddress("TradegenERC20")).transferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount, block.timestamp);
    }

    /**
    * @dev Unstakes TGEN from the protocol
    * @param amount Amount of TGEN to unstake
    */
    function unstake(uint amount) external override {
        require(amount > 0, "Cannot withdraw 0");

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);

        //Transfer staked TGEN from StakingRewards contract to user
        IERC20(ADDRESS_RESOLVER.getContractAddress("TradegenERC20")).transfer(msg.sender, amount);

        //Claim available yield on behalf of the user
        claimStakingRewards();

        emit Unstaked(msg.sender, amount, block.timestamp);
    }

    /**
    * @dev Claims available staking rewards for the user
    */
    function claimStakingRewards() public override {
        address stakingEscrowAddress = ADDRESS_RESOLVER.getContractAddress("StakingEscrow");
        uint availableRewards = _calculateAvailableYield(msg.sender);

        if (availableRewards > 0)
        {
            _userToState[msg.sender].leftoverYield = 0;
            _userToState[msg.sender].timestamp = uint32(block.timestamp);

            IStakingEscrow(stakingEscrowAddress).claimStakingRewards(msg.sender, availableRewards);

            emit ClaimedStakingRewards(msg.sender, availableRewards, block.timestamp);
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
    * @dev Calculates available yield (in TGEN) for the user
    * @param user Address of the user
    * @return uint The user's available yield
    */
    function _calculateAvailableYield(address user) internal view returns (uint) {
        if (_userToState[user].timestamp == 0)
        {
            return 0;
        }

        uint weeklyStakingRewards = ISettings(ADDRESS_RESOLVER.getContractAddress("Settings")).getParameterValue("WeeklyStakingRewards");
        uint elapsedTime = block.timestamp.sub(_userToState[user].timestamp);
        uint newYield = elapsedTime.mul(weeklyStakingRewards).mul(_balances[user]).div(7 days).div(_totalSupply);

        return uint256(_userToState[user].leftoverYield).add(newYield);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @dev Slashes the user's stake after a dubious vote and transfers the amount to StrategyVotingEscrow contract
    * @param user Address of the user
    * @param amount Amount of TGEN to remove from stake
    */
    function slashStake(address user, uint amount) public override onlyStrategyApproval {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(user != address(0), "Invalid user address");
        require(_balances[user] >= amount, "Not enough staked TGEN");

        _totalSupply = _totalSupply.sub(amount);
        _balances[user] = _balances[user].sub(amount);

        //Transfer staked TGEN from StakingRewards contract to StrategyVotingEscrow contract
        address strategyVotingEscrowAddress = ADDRESS_RESOLVER.getContractAddress("StrategyVotingEscrow");
        IERC20(ADDRESS_RESOLVER.getContractAddress("TradegenERC20")).transfer(strategyVotingEscrowAddress, amount);

        //Claim available yield on behalf of the user
        claimStakingRewards();
    }

    /* ========== MODIFIERS ========== */

    modifier onlyStrategyApproval() {
        require(msg.sender == strategyApprovalAddress, "Only the StrategyApproval contract can call this function");
        _;
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint amount, uint timestamp);
    event Unstaked(address indexed user, uint amount, uint timestamp);
    event ClaimedStakingRewards(address indexed user, uint amount, uint timestamp);
}