pragma solidity >=0.5.0;

//libraries
import './libraries/SafeMath.sol';

import './interfaces/IERC20.sol';

import './AddressResolver.sol';

contract StakingRewards is AddressResolver {
    using SafeMath for uint256;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor() public {
        _setStakingRewardsAddress(address(this));
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        IERC20(getBaseTradegenAddress()).restrictedTransfer(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount, block.timestamp);
    }

    function unstake(uint256 amount) public {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        IERC20(getBaseTradegenAddress()).restrictedTransfer(address(this), msg.sender, amount);
        emit Unstaked(msg.sender, amount, block.timestamp);
    }

    /* ========== EVENTS ========== */

    event Staked(address indexed user, uint256 amount, uint timestamp);
    event Unstaked(address indexed user, uint256 amount, uint timestamp);
}