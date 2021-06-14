pragma solidity >=0.5.0;

//Libraries
import './libraries/SafeMath.sol';

//Interfaces
import './interfaces/IERC20.sol';
import './interfaces/IAddressResolver.sol';
import './interfaces/ISettings.sol';
import './interfaces/ITradegen.sol';
import './interfaces/IStakingRewards.sol';

contract StakingRewards is IStakingRewards {
    using SafeMath for uint;

    IAddressResolver public immutable ADDRESS_RESOLVER;

    uint private _totalSupply;
    mapping(address => uint) private _balances;
    mapping(address => State) private _userToState;

    constructor(IAddressResolver addressResolver) public {
        ADDRESS_RESOLVER = addressResolver;
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

        //Transfer TGEN from StakingRewards contract to user
        IERC20(ADDRESS_RESOLVER.getContractAddress("TradegenERC20")).transferFrom(address(this), msg.sender, amount);

        //Claim available yield on behalf of the user
        _claimStakingRewards(msg.sender, _calculateAvailableYield(msg.sender));

        emit Unstaked(msg.sender, amount, block.timestamp);
    }

    /**
    * @dev Wrapper for internal claimStakingRewards() function 
    */
    function claimStakingRewards() external override {
        _claimStakingRewards(msg.sender, _calculateAvailableYield(msg.sender));
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

        uint yieldRate = ISettings(ADDRESS_RESOLVER.getContractAddress("Settings")).getParameterValue("StakingYield").div(100); //convert % to decimal
        uint newYield = (block.timestamp.sub(_userToState[user].timestamp).mul(yieldRate).mul(_balances[user])).div(365 days);

        return uint256(_userToState[user].leftoverYield).add(newYield);
    }

    /**
    * @dev Claims available yield for the user
    * @param user Address of the user
    * @param amount Amount of TGEN yield to claim
    */
    function _claimStakingRewards(address user, uint amount) internal {
        _userToState[user].leftoverYield = uint224(_calculateAvailableYield(user).sub(amount));
        _userToState[user].timestamp = uint32(block.timestamp);

        //Send TGEN rewards to user
        ITradegen(ADDRESS_RESOLVER.getContractAddress("BaseTradegen")).sendRewards(user, amount);

        emit ClaimedStakingRewards(user, amount, block.timestamp);
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint amount, uint timestamp);
    event Unstaked(address indexed user, uint amount, uint timestamp);
    event ClaimedStakingRewards(address indexed user, uint amount, uint timestamp);
}