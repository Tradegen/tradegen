pragma solidity >=0.5.0;

//libraries
import './libraries/SafeMath.sol';

import './interfaces/IERC20.sol';

import './AddressResolver.sol';

contract StakingRewards is AddressResolver {
    using SafeMath for uint;

    struct State {
        uint timestamp;
        uint leftoverYield;
    }

    uint256 private _totalSupply;
    mapping(address => uint) private _balances;
    mapping(address => State) private _userToState;

    constructor() public {
        _setStakingRewardsAddress(address(this));
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint) {
        return _balances[account];
    }

    function getAvailableYield() external view returns (uint) {
        return _calculateAvailableYield(msg.sender);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint amount) external {
        require(amount > 0, "Cannot stake 0");

        _userToState[msg.sender].timestamp = block.timestamp;
        _userToState[msg.sender].leftoverYield = _calculateAvailableYield(msg.sender);
        
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        IERC20(getBaseTradegenAddress()).restrictedTransfer(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount, block.timestamp);
    }

    function unstake(uint amount) external {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        IERC20(getBaseTradegenAddress()).restrictedTransfer(address(this), msg.sender, amount);
        _claimStakingRewards(msg.sender, _calculateAvailableYield(msg.sender));

        emit Unstaked(msg.sender, amount, block.timestamp);
    }

    function claimStakingRewards() external {
        _claimStakingRewards(msg.sender, _calculateAvailableYield(msg.sender));
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _calculateAvailableYield(address user) internal view returns (uint) {
        if (_userToState[user].timestamp == 0)
        {
            return 0;
        }

        uint yieldRate = 12; // 12% APY
        yieldRate = yieldRate.div(100);
        uint newYield = (block.timestamp.sub(_userToState[user].timestamp).mul(yieldRate).mul(_balances[user])).div(365 days);

        return _userToState[user].leftoverYield.add(newYield);
    }

    function _claimStakingRewards(address user, uint amount) internal {
        IERC20(getBaseTradegenAddress()).transferStakingRewards(user, amount);
        _userToState[user].leftoverYield = _calculateAvailableYield(user).sub(amount);
        _userToState[user].timestamp = block.timestamp;

        emit ClaimedStakingRewards(user, amount, block.timestamp);
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 amount, uint timestamp);
    event Unstaked(address indexed user, uint256 amount, uint timestamp);
    event ClaimedStakingRewards(address indexed user, uint256 amount, uint timestamp);
}