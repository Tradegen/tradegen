// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

// Adapters.
import './interfaces/IBaseUbeswapAdapter.sol';

// Inheritance.
import "./Ownable.sol";
import "./interfaces//ITradegenLPStakingRewards.sol";
import "./openzeppelin-solidity/ReentrancyGuard.sol";

// Libraries.
import "./openzeppelin-solidity/SafeMath.sol";
import "./openzeppelin-solidity/SafeERC20.sol";

// Internal references.
import "./interfaces/IAddressResolver.sol";
import "./interfaces/ISettings.sol";
import "./interfaces/IAssetHandler.sol";
import "./interfaces/ITradegenStakingEscrow.sol";
import "./interfaces/IBaseUbeswapAdapter.sol";
import "./interfaces/Ubeswap/IUniswapV2Pair.sol";

contract TradegenLPStakingRewards is Ownable, ITradegenLPStakingRewards, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    /* ========== CONSTANTS ========== */

    uint public constant TIME_INDEX = 0;
    uint public constant QUANTITY_INDEX = 1;
    uint public constant TOKENS_INDEX = 2;

    // Limit vesting entries to disallow unbounded iteration over vesting schedules.
    uint public constant MAX_VESTING_ENTRIES = 48;

    /* ========== STATE VARIABLES ========== */

    IAddressResolver public immutable ADDRESS_RESOLVER;

    // TGEN-CELO LP token.
    IERC20 public immutable STAKING_TOKEN;

    uint public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 public _totalSupply;
    mapping(address => uint256) public _balances;

    // Lists of (timestamp, quantity, tokens) tuples per account, sorted in ascending time order.
    // These are the times at which each given quantity of LP token vests.
    mapping(address => uint[3][]) public vestingSchedules;

    // An account's total vested TGEN-CELO LP token balance to save recomputing this.
    mapping(address => uint) public totalVestedAccountBalance;

    // The total remaining vested balance, for verifying the actual TGEN-CELO LP token balance of this contract against.
    uint public totalVestedBalance;

    /* ========== CONSTRUCTOR ========== */

    constructor(IAddressResolver _addressResolver, address _stakingToken) Ownable() {
        ADDRESS_RESOLVER = _addressResolver;
        STAKING_TOKEN = IERC20(_stakingToken);
        lastUpdateTime = block.timestamp;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Returns the number of reward tokens distributed per second.
     */
    function rewardRate() external view override returns (uint) {
        return ISettings(ADDRESS_RESOLVER.getContractAddress("Settings")).getParameterValue("WeeklyLPStakingRewards");
    }

    /**
     * @notice Returns the total number of LP tokens staked.
     */
    function totalSupply() external view override returns (uint) {
        return totalVestedBalance;
    }

    /**
     * @notice Returns the address of the reward token.
     */
    function rewardsToken() external view override returns (address) {
        return ADDRESS_RESOLVER.getContractAddress("TradegenERC20");
    }

    /**
     * @notice Returns the address of the LP token.
     */
    function stakingToken() public view override returns (address) {
        return address(STAKING_TOKEN);
    }

    /**
     * @notice Returns the number of LP tokens staked for the given user.
     * @param account Address of the user.
     */
    function balanceOf(address account) external view override returns (uint) {
        return totalVestedAccountBalance[account];
    }

    /**
     * @notice Returns the total number of vesting entries for the given user.
     * @param account Address of the user.
     */
    function numVestingEntries(address account) public view override returns (uint) {
        return vestingSchedules[account].length;
    }

    /**
     * @notice Returns the user's vesting entry at the given index.
     * @dev Returns [0, 0, 0] if the index is out of bounds.
     * @param account Address of the user.
     * @param index Index in the array of vesting entries.
     * @return uint[3] The timestamp, quantity, and number of tokens.
     */
    function getVestingScheduleEntry(address account, uint index) public view override returns (uint[3] memory) {
        return vestingSchedules[account][index];
    }

    /**
     * @notice Returns the timestamp at which the user's vesting entry will start vesting.
     * @dev Returns 0 if the index is out of bounds.
     * @param account Address of the user.
     * @param index Index in the array of vesting entries.
     * @return uint Timestamp at which vesting starts.
     */
    function getVestingTime(address account, uint index) public view override returns (uint) {
        return getVestingScheduleEntry(account, index)[TIME_INDEX];
    }

    /**
     * @notice Returns the number of LP tokens for the user's vesting entry.
     * @dev Returns 0 if the index is out of bounds.
     * @param account Address of the user.
     * @param index Index in the array of vesting entries.
     * @return uint Number of LP tokens.
     */
    function getVestingQuantity(address account, uint index) public view override returns (uint) {
        return getVestingScheduleEntry(account, index)[QUANTITY_INDEX];
    }

    /**
     * @notice Returns the adjusted weight for the user's vesting entry.
     * @dev Returns 0 if the index is out of bounds.
     * @param account Address of the user.
     * @param index Index in the array of vesting entries.
     * @return uint Adjusted weight.
     */
    function getVestingTokenAmount(address account, uint index) public view override returns (uint) {
        return getVestingScheduleEntry(account, index)[TOKENS_INDEX];
    }

    /**
     * @notice Returns the index of the user's next vesting entry.
     * @param account Address of the user.
     * @return uint Index of the user's next vesting entry.
     */
    function getNextVestingIndex(address account) public view override returns (uint) {
        uint len = numVestingEntries(account);

        for (uint i = 0; i < len; i++)
        {
            if (getVestingTime(account, i) != 0)
            {
                return i;
            }
        }

        return len;
    }

    /**
     * @notice Returns the current reward per LP token staked.
     */
    function rewardPerToken() public view override returns (uint) {
        uint rate = ISettings(ADDRESS_RESOLVER.getContractAddress("Settings")).getParameterValue("WeeklyLPStakingRewards");

        if (_totalSupply == 0)
        {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored.add(block.timestamp.sub(lastUpdateTime).mul(rate).div(7 days).mul(1e18).div(_totalSupply));
    }

    /**
     * @notice Returns the amount of rewards available for the given user.
     * @param account Address of the user.
     */
    function earned(address account) public view override returns (uint) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    /**
     * @notice Returns the user's next vesting entry.
     * @param account Address of the user.
     * @return uint[3] The timestamp, quantity, and adjusted weight of the next entry.
     */
    function getNextVestingEntry(address account) public view override returns (uint[3] memory) {
        uint index = getNextVestingIndex(account);

        if (index == numVestingEntries(account))
        {
            return [uint(0), 0, 0];
        }

        return getVestingScheduleEntry(account, index);
    }

    /**
     * @notice Returns the timestamp of the user's next vesting entry.
     * @param account Address of the user.
     * @return uint Timestamp of the user's next vesting entry.
     */
    function getNextVestingTime(address account) external view override returns (uint) {
        return getNextVestingEntry(account)[TIME_INDEX];
    }

    /**
     * @notice Returns the vesting amount of the user's next vesting entry.
     * @param account Address of the user.
     * @return uint Vesting amount of the user's next vesting entry.
     */
    function getNextVestingQuantity(address account) external view override returns (uint) {
        return getNextVestingEntry(account)[QUANTITY_INDEX];
    }

    /**
     * @notice Returns the USD value of all LP tokens staked in this contract.
     */
    function getUSDValueOfContract() external view override returns (uint) {
        return (_totalSupply > 0) ? calculateValueOfLPTokens(totalVestedBalance) : 0;
    }

    /**
     * @notice Calculates the USD value of the given number of LP tokens.
     * @param numberOfTokens Number of LP tokens in the farm.
     * @return uint The USD value of the LP tokens.
     */
    function calculateValueOfLPTokens(uint numberOfTokens) public view override returns (uint) {
        require(numberOfTokens > 0, "TradegenLPStakingRewards: Number of LP tokens in pair must be greater than 0.");

        address baseUbeswapAdapterAddress = ADDRESS_RESOLVER.getContractAddress("BaseUbeswapAdapter"); 

        address pair = stakingToken();
        address tokenA = IUniswapV2Pair(pair).token0();
        address tokenB = IUniswapV2Pair(pair).token1();
        (uint amountA, uint amountB) = IBaseUbeswapAdapter(baseUbeswapAdapterAddress).getTokenAmountsFromPair(tokenA, tokenB, numberOfTokens);

        uint USDperTokenA = IBaseUbeswapAdapter(baseUbeswapAdapterAddress).getPrice(tokenA);
        uint USDBalanceA = amountA.mul(USDperTokenA).div(10 ** 18);

        uint USDperTokenB = IBaseUbeswapAdapter(baseUbeswapAdapterAddress).getPrice(tokenB);
        uint USDBalanceB = amountB.mul(USDperTokenB).div(10 ** 18);

        return USDBalanceA.mul(USDBalanceB);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice Add a new vesting entry at a given time and quantity to an account's schedule.
     * @param account The account to append a new vesting entry to.
     * @param time The absolute unix timestamp after which the vested quantity may be withdrawn.
     * @param quantity The quantity of TGEN-CELO LP that will vest.
     * @param numberOfTokens Number of tokens to issue, base on staked quantity and number of weeks
     */
    function appendVestingEntry(address account, uint time, uint quantity, uint numberOfTokens) internal {
        // No empty or already-passed vesting entries allowed.
        require(block.timestamp <= time, "TradegenLPStakingRewards: Time must be in the future.");
        require(quantity != 0, "TradegenLPStakingRewards: Quantity cannot be zero.");
        require(numberOfTokens > 0, "TradegenLPStakingRewards: Number of tokens must be greater than 0.");

        // Disallow arbitrarily long vesting schedules in light of the gas limit.
        uint scheduleLength = vestingSchedules[account].length;

        if (scheduleLength == 0)
        {
            totalVestedAccountBalance[account] = quantity;
            _balances[account] = numberOfTokens;

            vestingSchedules[account].push([time, quantity, numberOfTokens]);
        }
        else
        {
            // Look for empty spot before appending new entry.
            bool foundEmptySpot = false;
            for (uint i = 0; i < scheduleLength; i++)
            {
                if (getVestingQuantity(account, i) == 0)
                {
                    vestingSchedules[account][i] = [time, quantity, numberOfTokens];
                    foundEmptySpot = true;
                }
            }

            if (!foundEmptySpot)
            {
                require(scheduleLength <= MAX_VESTING_ENTRIES, "TradegenLPStakingRewards: Vesting schedule is too long.");
                vestingSchedules[account].push([time, quantity, numberOfTokens]);
            }

            totalVestedAccountBalance[account] = totalVestedAccountBalance[account].add(quantity);
            _balances[account] = _balances[account].add(numberOfTokens);
        }  

        emit AppendedVestingEntry(account, time, quantity, numberOfTokens, block.timestamp);
    }

    /**
     * @notice Claims available rewards for the given user.
     */
    function _claim(address user) internal updateReward(user) {
        address tradegenLPStakingEscrowAddress = ADDRESS_RESOLVER.getContractAddress("TradegenLPStakingEscrow");
        uint reward = rewards[user];

        if (reward > 0)
        {
            rewards[user] = 0;
            ITradegenStakingEscrow(tradegenLPStakingEscrowAddress).claimStakingRewards(user, reward);
            emit RewardPaid(user, reward, block.timestamp);
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Stakes LP tokens for the given number of weeks.
     * @dev The number of weeks is capped at 52.
     * @param amount Number of LP tokens to stake.
     * @param numberOfWeeks Number of weeks to stake.
     */
    function stake(uint amount, uint numberOfWeeks) external override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "TradegenLPStakingRewards: Staked amount must be greater than 0.");
        require(numberOfWeeks >= 0 && numberOfWeeks <= 52, "TradegenLPStakingRewards: number of weeks must be between 0 and 52.");

        // Up to 2x multiplier depending on number of weeks staked.
        uint vestingTimestamp = block.timestamp.add(uint(1 weeks).mul(numberOfWeeks));
        uint adjustedAmount = amount.mul(numberOfWeeks.add(52)).div(52);

        _totalSupply = _totalSupply.add(adjustedAmount);
        appendVestingEntry(msg.sender, vestingTimestamp, amount, adjustedAmount);

        totalVestedBalance = totalVestedBalance.add(amount);
        STAKING_TOKEN.safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount, vestingTimestamp, block.timestamp);
    }

    /**
     * @notice Withdraws any LP tokens that have vested.
     */
    function vest() external override nonReentrant updateReward(msg.sender) {
        uint numEntries = numVestingEntries(msg.sender);
        uint total;
        uint tokenTotal;

        // Claim rewards before withdrawing, since rewards calculation will fail if total supply is 0 after withdrawing.
        _claim(msg.sender);

        for (uint i = 0; i < numEntries; i++)
        {
            uint qty = getVestingQuantity(msg.sender, i);
            uint numberOfTokens = getVestingTokenAmount(msg.sender, i);
            uint time = getVestingTime(msg.sender, i);

            if (qty > 0 && time <= block.timestamp)
            {
                vestingSchedules[msg.sender][i] = [0, 0, 0];
                total = total.add(qty);
                tokenTotal = tokenTotal.add(numberOfTokens);
            }
        }

        if (total != 0 || tokenTotal != 0)
        {
            totalVestedBalance = totalVestedBalance.sub(total);
            totalVestedAccountBalance[msg.sender] = totalVestedAccountBalance[msg.sender].sub(total);
            _totalSupply = _totalSupply.sub(tokenTotal);
            _balances[msg.sender] = _balances[msg.sender].sub(tokenTotal);

            STAKING_TOKEN.safeTransfer(msg.sender, total);

            emit Vested(msg.sender, block.timestamp, total);
        }
    }

    /**
     * @notice Claims any available staking rewards.
     */
    function getReward() external override nonReentrant {
        _claim(msg.sender);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event Vested(address indexed beneficiary, uint time, uint value);
    event Staked(address indexed beneficiary, uint total, uint vestingTimestamp, uint timestamp);
    event RewardPaid(address indexed user, uint amount, uint timestamp);
    event AppendedVestingEntry(address indexed account, uint time, uint quantity, uint numberOfTokens, uint timestamp);
}