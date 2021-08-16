// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

//Adapters
import './interfaces/IBaseUbeswapAdapter.sol';

// Inheritance
import "./Ownable.sol";
import "./interfaces//ITradegenLPStakingRewards.sol";
import "./openzeppelin-solidity/ReentrancyGuard.sol";

// Libraries
import "./libraries/SafeMath.sol";

// Internal references
import "./interfaces/IERC20.sol";
import "./interfaces/IAddressResolver.sol";
import "./interfaces/ISettings.sol";
import "./interfaces/IAssetHandler.sol";
import "./interfaces/IBaseUbeswapAdapter.sol";
import "./interfaces/Ubeswap/IUniswapV2Pair.sol";

contract TradegenLPStakingRewards is Ownable, ITradegenLPStakingRewards, ReentrancyGuard {
    using SafeMath for uint;

    IAddressResolver public immutable ADDRESS_RESOLVER;

    uint public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    /* Lists of (timestamp, quantity) pairs per account, sorted in ascending time order.
     * These are the times at which each given quantity of LP token vests. */
    mapping(address => uint[2][]) public vestingSchedules;

    /* An account's total vested TGEN-cUSD LP token balance to save recomputing this */
    mapping(address => uint) public totalVestedAccountBalance;

    /* The total remaining vested balance, for verifying the actual TGEN-cUSD LP token balance of this contract against. */
    uint public totalVestedBalance;

    uint public constant TIME_INDEX = 0;
    uint public constant QUANTITY_INDEX = 1;

    /* Limit vesting entries to disallow unbounded iteration over vesting schedules. */
    uint public constant MAX_VESTING_ENTRIES = 48;

    /* ========== CONSTRUCTOR ========== */

    constructor(IAddressResolver _addressResolver) public Ownable() {
        ADDRESS_RESOLVER = _addressResolver;
        lastUpdateTime = block.timestamp;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function rewardRate() public view override returns (uint) {
        return ISettings(ADDRESS_RESOLVER.getContractAddress("Settings")).getParameterValue("WeeklyLPStakingFarmRewards");
    }

    function totalSupply() public view override returns (uint) {
        return totalVestedBalance;
    }

    function stakingToken() public view override returns (address) {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address baseUbeswapAdapterAddress = ADDRESS_RESOLVER.getContractAddress("BaseUbeswapAdapter");
        address stableCoinAddress = IAssetHandler(assetHandlerAddress).getStableCoinAddress();
        address TGEN = ADDRESS_RESOLVER.getContractAddress("TradegenERC20");

        return IBaseUbeswapAdapter(baseUbeswapAdapterAddress).getPair(TGEN, stableCoinAddress);
    }

    function rewardsToken() external view override returns (address) {
        return ADDRESS_RESOLVER.getContractAddress("TradegenERC20");
    }

    /**
     * @notice A simple alias to totalVestedAccountBalance: provides ERC20 balance integration.
     */
    function balanceOf(address account) public view override returns (uint) {
        return totalVestedAccountBalance[account];
    }

    /**
     * @notice The number of vesting dates in an account's schedule.
     */
    function numVestingEntries(address account) public view override returns (uint) {
        return vestingSchedules[account].length;
    }

    /**
     * @notice Get a particular schedule entry for an account.
     * @return A pair of uints: (timestamp, TGEN-cUSD LP quantity).
     */
    function getVestingScheduleEntry(address account, uint index) public view override returns (uint[2] memory) {
        return vestingSchedules[account][index];
    }

    /**
     * @notice Get the time at which a given schedule entry will vest.
     */
    function getVestingTime(address account, uint index) public view override returns (uint) {
        return getVestingScheduleEntry(account, index)[TIME_INDEX];
    }

    /**
     * @notice Get the quantity of TGEN-cUSD LP associated with a given schedule entry.
     */
    function getVestingQuantity(address account, uint index) public view override returns (uint) {
        return getVestingScheduleEntry(account, index)[QUANTITY_INDEX];
    }

    /**
     * @notice Obtain the index of the next schedule entry that will vest for a given user.
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
     * @notice Calculates the amount of TGEN reward per token stored
     */
    function rewardPerToken() public view override returns (uint) {
        uint rewardRate = ISettings(ADDRESS_RESOLVER.getContractAddress("Settings")).getParameterValue("WeeklyLPStakingFarmRewards");

        if (totalVestedBalance == 0)
        {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored.add(block.timestamp.sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(totalVestedBalance));
    }

    /**
     * @notice Calculates the amount of TGEN rewards earned
     */
    function earned(address account) public view override returns (uint) {
        return totalVestedAccountBalance[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    /**
     * @notice Obtain the next schedule entry that will vest for a given user.
     * @return A pair of uints: (timestamp, TGEN-cUSD LP quantity). */
    function getNextVestingEntry(address account) public view override returns (uint[2] memory) {
        uint index = getNextVestingIndex(account);
        if (index == numVestingEntries(account))
        {
            return [uint(0), 0];
        }

        return getVestingScheduleEntry(account, index);
    }

    /**
     * @notice Obtain the time at which the next schedule entry will vest for a given user.
     */
    function getNextVestingTime(address account) external view override returns (uint) {
        return getNextVestingEntry(account)[TIME_INDEX];
    }

    /**
     * @notice Obtain the quantity which the next schedule entry will vest for a given user.
     */
    function getNextVestingQuantity(address account) external view override returns (uint) {
        return getNextVestingEntry(account)[QUANTITY_INDEX];
    }

    /**
     * @notice Returns the USD value of all LP tokens staked in this contract
     * @return uint USD value of this contract
     */
    function getUSDValueOfContract() public view override returns (uint) {
        return _calculateValueOfLPTokens(totalVestedBalance);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice Add a new vesting entry at a given time and quantity to an account's schedule.
     * @param account The account to append a new vesting entry to.
     * @param time The absolute unix timestamp after which the vested quantity may be withdrawn.
     * @param quantity The quantity of TGEN-cUSD LP that will vest.
     */
    function appendVestingEntry(address account, uint time, uint quantity) internal {
        /* No empty or already-passed vesting entries allowed. */
        require(block.timestamp < time, "Time must be in the future");
        require(quantity != 0, "Quantity cannot be zero");

        /* Disallow arbitrarily long vesting schedules in light of the gas limit. */
        uint scheduleLength = vestingSchedules[account].length;
        require(scheduleLength <= MAX_VESTING_ENTRIES, "Vesting schedule is too long");

        if (scheduleLength == 0)
        {
            totalVestedAccountBalance[account] = quantity;
        }
        else
        {
            /* Disallow adding new vested TGEN-cUSD LP earlier than the last one.
             * Since entries are only appended, this means that no vesting date can be repeated. */
            require(
                getVestingTime(account, numVestingEntries(account) - 1) < time,
                "Cannot add new vested entries earlier than the last one"
            );

            totalVestedAccountBalance[account] = totalVestedAccountBalance[account].add(quantity);
        }

        vestingSchedules[account].push([time, quantity]);
    }

    /**
     * @notice Calculates the USD value of the given number of LP tokens
     * @param numberOfTokens Number of LP tokens in the farm
     * @return uint The USD value of the LP tokens
     */
    function _calculateValueOfLPTokens(uint numberOfTokens) internal view returns (uint) {
        require(numberOfTokens > 0, "TradegenLPStakingRewards: number of LP tokens in pair must be greater than 0");

        address baseUbeswapAdapterAddress = ADDRESS_RESOLVER.getContractAddress("BaseUbeswapAdapter"); 

        address pair = stakingToken();
        address tokenA = IUniswapV2Pair(pair).token0();
        address tokenB = IUniswapV2Pair(pair).token1();
        (uint amountA, uint amountB) = IBaseUbeswapAdapter(baseUbeswapAdapterAddress).getTokenAmountsFromPair(tokenA, tokenB, numberOfTokens);

        uint numberOfDecimalsA = IERC20(tokenA).decimals();
        uint USDperTokenA = IBaseUbeswapAdapter(baseUbeswapAdapterAddress).getPrice(tokenA);
        uint USDBalanceA = amountA.mul(USDperTokenA).div(10 ** numberOfDecimalsA);

        uint numberOfDecimalsB = IERC20(tokenB).decimals();
        uint USDperTokenB = IBaseUbeswapAdapter(baseUbeswapAdapterAddress).getPrice(tokenB);
        uint USDBalanceB = amountB.mul(USDperTokenB).div(10 ** numberOfDecimalsB);

        return USDBalanceA.mul(USDBalanceB);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Stakes the given TGEN-cUSD LP amount.
     */
    function stake(uint amount, uint numberOfWeeks) external override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "TradegenLPStakingRewards: Staked amount must be greater than 0");
        require(numberOfWeeks > 0 && numberOfWeeks <= 52, "TradegenLPStakingRewards: number of weeks must be between 1 and 52");

        //Up to 2x multiplier depending on number of weeks staked
        uint vestingTimestamp = block.timestamp.add((1 weeks).mul(numberOfWeeks));
        uint adjustedAmount = amount.mul(numberOfWeeks.add(1)).div(numberOfWeeks);
        appendVestingEntry(msg.sender, vestingTimestamp, adjustedAmount);

        totalVestedBalance = totalVestedBalance.add(adjustedAmount);
        IERC20(stakingToken()).transferFrom(msg.sender, address(this), adjustedAmount);

        emit Staked(msg.sender, adjustedAmount, vestingTimestamp, block.timestamp);
    }

    /**
     * @notice Allow a user to withdraw any TGEN-cUSD LP in their schedule that have vested.
     */
    function vest() external override nonReentrant updateReward(msg.sender) {
        uint numEntries = numVestingEntries(msg.sender);
        uint total;

        for (uint i = 0; i < numEntries; i++)
        {
            uint time = getVestingTime(msg.sender, i);
            /* The list is sorted; when we reach the first future time, bail out. */
            if (time > block.timestamp)
            {
                break;
            }

            uint qty = getVestingQuantity(msg.sender, i);

            if (qty > 0)
            {
                vestingSchedules[msg.sender][i] = [0, 0];
                total = total.add(qty);
            }
        }

        if (total != 0)
        {
            totalVestedBalance = totalVestedBalance.sub(total);
            totalVestedAccountBalance[msg.sender] = totalVestedAccountBalance[msg.sender].sub(total);

            IERC20(stakingToken()).transfer(msg.sender, total);

            emit Vested(msg.sender, block.timestamp, total);
        }

        getReward();
    }

    /**
     * @notice Allow a user to claim any available staking rewards
     */
    function getReward() public override nonReentrant updateReward(msg.sender) {
        address TGEN = ADDRESS_RESOLVER.getContractAddress("TradegenERC20");
        uint reward = rewards[msg.sender];

        if (reward > 0)
        {
            rewards[msg.sender] = 0;
            IERC20(TGEN).transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward, block.timestamp);
        }
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
}