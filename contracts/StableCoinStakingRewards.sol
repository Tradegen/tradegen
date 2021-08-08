pragma solidity >=0.5.0;

// Inheritance
import "./Ownable.sol";
import "./interfaces/IStableCoinStakingRewards.sol";
import "./openzeppelin-solidity/ReentrancyGuard.sol";

// Libraires
import "./libraries/SafeMath.sol";

// Internal references
import "./interfaces/IERC20.sol";
import "./interfaces/IAddressResolver.sol";
import "./interfaces/ISettings.sol";

contract StableCoinStakingRewards is Ownable, IStableCoinStakingRewards, ReentrancyGuard {
    using SafeMath for uint;

    IAddressResolver public immutable ADDRESS_RESOLVER;

    uint public lastUpdateTime;
    uint public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    /* Lists of (timestamp, quantity) pairs per account, sorted in ascending time order.
     * These are the times at which each given quantity of cUSD vests. */
    mapping(address => uint[2][]) public vestingSchedules;

    /* An account's total vested cUSD balance to save recomputing this */
    mapping(address => uint) public totalVestedAccountBalance;

    /* The total remaining vested balance, for verifying the actual Tradegen balance of this contract against. */
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
     * @return A pair of uints: (timestamp, cUSD quantity).
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
     * @notice Get the quantity of cUSD associated with a given schedule entry.
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
     * @notice Calculates the amount of TGEN reward per token staked.
     */
    function rewardPerToken() public view override returns (uint256) {
        address settingsAddress = ADDRESS_RESOLVER.getContractAddress("Settings");
        uint rewardRate = ISettings(settingsAddress).getParameterValue("WeeklyStableCoinStakingRewards");

        if (totalVestedBalance == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                block.timestamp.sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(totalVestedBalance)
            );
    }

    /**
     * @notice Calculates the amount of TGEN rewards earned.
     */
    function earned(address account) public view override returns (uint256) {
        return totalVestedAccountBalance[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    /**
     * @notice Obtain the next schedule entry that will vest for a given user.
     * @return A pair of uints: (timestamp, cUSD quantity). */
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

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice Add a new vesting entry at a given time and quantity to an account's schedule.
     * @param account The account to append a new vesting entry to.
     * @param time The absolute unix timestamp after which the vested quantity may be withdrawn.
     * @param quantity The quantity of cUSD that will vest.
     */
    function appendVestingEntry(address account, uint time, uint quantity) internal {
        address settingsAddress = ADDRESS_RESOLVER.getContractAddress("Settings");
        address stableCoinAddress = ISettings(settingsAddress).getStableCoinAddress();

        /* No empty or already-passed vesting entries allowed. */
        require(block.timestamp < time, "Time must be in the future");
        require(quantity != 0, "Quantity cannot be zero");

        /* There must be enough balance in the contract to provide for the vesting entry. */
        totalVestedBalance = totalVestedBalance.add(quantity);
        require(
            totalVestedBalance <= IERC20(stableCoinAddress).balanceOf(address(this)),
            "Must be enough balance in the contract to provide for the vesting entry"
        );

        /* Disallow arbitrarily long vesting schedules in light of the gas limit. */
        uint scheduleLength = vestingSchedules[account].length;
        require(scheduleLength <= MAX_VESTING_ENTRIES, "Vesting schedule is too long");

        if (scheduleLength == 0)
        {
            totalVestedAccountBalance[account] = quantity;
        }
        else
        {
            /* Disallow adding new vested cUSD earlier than the last one.
             * Since entries are only appended, this means that no vesting date can be repeated. */
            require(
                getVestingTime(account, numVestingEntries(account) - 1) < time,
                "Cannot add new vested entries earlier than the last one"
            );

            totalVestedAccountBalance[account] = totalVestedAccountBalance[account].add(quantity);
        }

        vestingSchedules[account].push([time, quantity]);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Stakes the given cUSD amount.
     */
    function stake(uint amount) external override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "StableCoinStakingRewards: Staked amount must be greater than 0");

        uint vestingTimestamp = block.timestamp.add(30 days);
        appendVestingEntry(msg.sender, vestingTimestamp, amount);

        emit Staked(msg.sender, amount, vestingTimestamp, block.timestamp);
    }

    /**
     * @notice Allow a user to withdraw any cUSD in their schedule that have vested.
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
            address settingsAddress = ADDRESS_RESOLVER.getContractAddress("Settings");
            address stableCoinAddress = ISettings(settingsAddress).getStableCoinAddress();
            totalVestedBalance = totalVestedBalance.sub(total);
            totalVestedAccountBalance[msg.sender] = totalVestedAccountBalance[msg.sender].sub(total);
            IERC20(stableCoinAddress).transfer(msg.sender, total);

            emit Vested(msg.sender, block.timestamp, total);
        }

        getReward();
    }

    /**
     * @notice Allow a user to claim any available staking rewards.
     */
    function getReward() public override nonReentrant updateReward(msg.sender) {
        address baseTradegenAddress = ADDRESS_RESOLVER.getContractAddress("BaseTradegen");
        uint reward = rewards[msg.sender];

        if (reward > 0)
        {
            rewards[msg.sender] = 0;
            IERC20(baseTradegenAddress).transfer(msg.sender, reward);
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