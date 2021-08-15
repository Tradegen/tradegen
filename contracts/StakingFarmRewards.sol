pragma solidity >=0.5.0;

// Inheritance
import "./Ownable.sol";
import "./interfaces/IStakingFarmRewards.sol";
import "./openzeppelin-solidity/ReentrancyGuard.sol";

// Libraires
import "./libraries/SafeMath.sol";

// Internal references
import "./interfaces/IERC20.sol";
import "./interfaces/IAddressResolver.sol";
import "./interfaces/ISettings.sol";
import './interfaces/IBaseUbeswapAdapter.sol';
import "./interfaces/Ubeswap/IStakingRewards.sol";
import "./interfaces/Ubeswap/IUniswapV2Pair.sol";

contract StakingFarmRewards is Ownable, IStakingFarmRewards, ReentrancyGuard {
    using SafeMath for uint;

    IAddressResolver public immutable ADDRESS_RESOLVER;
    bool private initialized = false;

    mapping (address => uint) public lastUpdateTime;
    mapping (address => uint) public rewardPerTokenStored;
    mapping (address => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping (address => mapping(address => uint256)) public rewards;

    /* Lists of (timestamp, quantity) pairs per account, sorted in ascending time order.
     * These are the times at which each given quantity of LP token vests. */
    mapping (address => mapping(address => uint[2][])) public vestingSchedules;

    /* An account's total vested LP token balance to save recomputing this */
    mapping (address => mapping(address => uint)) public totalVestedAccountBalance;

    /* The total remaining vested balance, for verifying the actual LP token balance of this contract against. */
    mapping (address => uint) public totalVestedBalance;

    uint public constant TIME_INDEX = 0;
    uint public constant QUANTITY_INDEX = 1;

    /* Limit vesting entries to disallow unbounded iteration over vesting schedules. */
    uint public constant MAX_VESTING_ENTRIES = 48;

    /* ========== CONSTRUCTOR ========== */

    constructor(IAddressResolver _addressResolver) public Ownable() {
        ADDRESS_RESOLVER = _addressResolver;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice A simple alias to totalVestedAccountBalance: provides ERC20 balance integration.
     */
    function balanceOf(address account, address farmAddress) public view override returns (uint) {
        require(farmAddress != address(0), "StakingFarmRewards: invalid farm address");
        require(account != address(0), "StakingFarmRewards: invalid account address");

        return totalVestedAccountBalance[farmAddress][account];
    }

    /**
     * @notice The number of vesting dates in an account's schedule for the given farm.
     */
    function numVestingEntries(address account, address farmAddress) public view override returns (uint) {
        require(farmAddress != address(0), "StakingFarmRewards: invalid farm address");
        require(account != address(0), "StakingFarmRewards: invalid account address");

        return vestingSchedules[farmAddress][account].length;
    }

    /**
     * @notice Get a particular schedule entry for an account for the given farm.
     * @return A pair of uints: (timestamp, LP token quantity).
     */
    function getVestingScheduleEntry(address account, uint index, address farmAddress) public view override returns (uint[2] memory) {
        require(farmAddress != address(0), "StakingFarmRewards: invalid farm address");
        require(account != address(0), "StakingFarmRewards: invalid account address");

        return vestingSchedules[farmAddress][account][index];
    }

    /**
     * @notice Get the time at which a given schedule entry will vest.
     */
    function getVestingTime(address account, uint index, address farmAddress) public view override returns (uint) {
        require(farmAddress != address(0), "StakingFarmRewards: invalid farm address");
        require(account != address(0), "StakingFarmRewards: invalid account address");

        return getVestingScheduleEntry(account, index, farmAddress)[TIME_INDEX];
    }

    /**
     * @notice Get the quantity of LP tokens associated with a given schedule entry for the given farm.
     */
    function getVestingQuantity(address account, uint index, address farmAddress) public view override returns (uint) {
        require(farmAddress != address(0), "StakingFarmRewards: invalid farm address");
        require(account != address(0), "StakingFarmRewards: invalid account address");

        return getVestingScheduleEntry(account, index, farmAddress)[QUANTITY_INDEX];
    }

    /**
     * @notice Obtain the index of the next schedule entry that will vest for a given user.
     */
    function getNextVestingIndex(address account, address farmAddress) public view override returns (uint) {
        require(farmAddress != address(0), "StakingFarmRewards: invalid farm address");
        require(account != address(0), "StakingFarmRewards: invalid account address");

        uint len = numVestingEntries(account, farmAddress);

        for (uint i = 0; i < len; i++)
        {
            if (getVestingTime(account, i, farmAddress) != 0)
            {
                return i;
            }
        }

        return len;
    }

    /**
     * @notice Calculates the amount of TGEN reward per token staked in the given farm.
     */
    function rewardPerToken(address farmAddress) public view override returns (uint256) {
        require(farmAddress != address(0), "StakingFarmRewards: invalid farm address");

        uint rewardRate = ISettings(ADDRESS_RESOLVER.getContractAddress("Settings")).getParameterValue("WeeklyStakingFarmRewards");
        uint numberOfAvailableFarms = IBaseUbeswapAdapter(ADDRESS_RESOLVER.getContractAddress("BaseUbeswapAdapter")).getAvailableUbeswapFarms().length;

        if (totalVestedBalance[farmAddress] == 0) {
            return rewardPerTokenStored[farmAddress];
        }
        return
            rewardPerTokenStored[farmAddress].add(
                block.timestamp.sub(lastUpdateTime[farmAddress]).mul(rewardRate).mul(1e18).div(totalVestedBalance[farmAddress]).div(numberOfAvailableFarms)
            );
    }

    /**
     * @notice Calculates the amount of TGEN rewards earned for the given farm.
     */
    function earned(address account, address farmAddress) public view override returns (uint256) {
        require(farmAddress != address(0), "StakingFarmRewards: invalid farm address");

        return totalVestedAccountBalance[farmAddress][account].mul(rewardPerToken(farmAddress).sub(userRewardPerTokenPaid[farmAddress][account])).div(1e18).add(rewards[farmAddress][account]);
    }

    /**
     * @notice Obtain the next schedule entry that will vest for a given user.
     * @return A pair of uints: (timestamp, LP token quantity). */
    function getNextVestingEntry(address account, address farmAddress) public view override returns (uint[2] memory) {
        require(farmAddress != address(0), "StakingFarmRewards: invalid farm address");
        require(account != address(0), "StakingFarmRewards: invalid account address");

        uint index = getNextVestingIndex(account, farmAddress);
        if (index == numVestingEntries(account, farmAddress))
        {
            return [uint(0), 0];
        }

        return getVestingScheduleEntry(account, index, farmAddress);
    }

    /**
     * @notice Obtain the time at which the next schedule entry will vest for a given user.
     */
    function getNextVestingTime(address account, address farmAddress) external view override returns (uint) {
        require(farmAddress != address(0), "StakingFarmRewards: invalid farm address");
        require(account != address(0), "StakingFarmRewards: invalid account address");

        return getNextVestingEntry(account, farmAddress)[TIME_INDEX];
    }

    /**
     * @notice Obtain the quantity which the next schedule entry will vest for a given user.
     */
    function getNextVestingQuantity(address account, address farmAddress) external view override returns (uint) {
        require(farmAddress != address(0), "StakingFarmRewards: invalid farm address");
        require(account != address(0), "StakingFarmRewards: invalid account address");

        return getNextVestingEntry(account, farmAddress)[QUANTITY_INDEX];
    }

    /**
     * @notice Returns the user's staked farms, balance in each staked farm, and the number of staked farms
     * @param account Address of the user
     * @return (address[], uint[], uint) The address of each staked farm, user's LP token balance in the associated farm, and the number of staked farms
     */
    function getStakedFarms(address account) public view override returns (address[] memory, uint[] memory, uint) {
        require(account != address(0), "StakingFarmRewards: invalid account address");

        address baseUbeswapAdapterAddress = ADDRESS_RESOLVER.getContractAddress("BaseUbeswapAdapter");   
        address[] memory availableFarms = IBaseUbeswapAdapter(baseUbeswapAdapterAddress).getAvailableUbeswapFarms();
        address[] memory stakedFarms = new address[](availableFarms.length);
        uint[] memory balances = new uint[](availableFarms.length);
        uint count = 0;

        for (uint i = 0; i < availableFarms.length; i++)
        {
            if (totalVestedAccountBalance[availableFarms[i]][account] > 0)
            {
                stakedFarms[count] = availableFarms[i];
                balances[count] = totalVestedAccountBalance[availableFarms[i]][account];
            }
        }   

        return (stakedFarms, balances, count); 
    }

    /**
     * @notice Returns the USD value of the user's staked position in the given farm
     * @param account Address of the user
     * @param farmAddress Address of the farm
     * @return uint USD value of the staked position
     */
    function getUSDValueOfStakedPosition(address account, address farmAddress) public view override returns (uint) {
        require(farmAddress != address(0), "StakingFarmRewards: invalid farm address");
        require(account != address(0), "StakingFarmRewards: invalid account address");

        uint numberOfLPTokens = totalVestedAccountBalance[farmAddress][account];

        return _calculateValueOfPair(farmAddress, numberOfLPTokens);
    }

    /**
     * @notice Returns the USD value of the given farm
     * @param farmAddress Address of the farm
     * @return uint USD value staked in the farm
     */
    function getUSDValueOfFarm(address farmAddress) public view override returns (uint) {
        require(farmAddress != address(0), "StakingFarmRewards: invalid farm address");

        uint totalSupply = totalVestedBalance[farmAddress];
        
        return _calculateValueOfPair(farmAddress, totalSupply);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice Add a new vesting entry at a given time and quantity to an account's schedule for the given farm.
     * @param account The account to append a new vesting entry to.
     * @param time The absolute unix timestamp after which the vested quantity may be withdrawn.
     * @param quantity The quantity of LP token that will vest.
     * @param farmAddress Address of the farm to stake in
     */
    function appendVestingEntry(address account, uint time, uint quantity, address farmAddress) internal {
        require(farmAddress != address(0), "StakingFarmRewards: invalid farm address");
        require(account != address(0), "StakingFarmRewards: invalid account address");


        /* No empty or already-passed vesting entries allowed. */
        require(block.timestamp < time, "Time must be in the future");
        require(quantity != 0, "Quantity cannot be zero");

        /* Disallow arbitrarily long vesting schedules in light of the gas limit. */
        uint scheduleLength = vestingSchedules[farmAddress][account].length;
        require(scheduleLength <= MAX_VESTING_ENTRIES, "Vesting schedule is too long");

        if (scheduleLength == 0)
        {
            totalVestedAccountBalance[farmAddress][account] = quantity;
        }
        else
        {
            /* Disallow adding new vested LP token earlier than the last one.
             * Since entries are only appended, this means that no vesting date can be repeated. */
            require(
                getVestingTime(account, numVestingEntries(account, farmAddress) - 1, farmAddress) < time,
                "Cannot add new vested entries earlier than the last one"
            );

            totalVestedAccountBalance[farmAddress][account] = totalVestedAccountBalance[farmAddress][account].add(quantity);
        }

        vestingSchedules[farmAddress][account].push([time, quantity]);
    }

    /**
     * @notice Given the address of a farm and the number of LP tokens, returns the USD value of the LP tokens.
     * @param farmAddress Address of the farm to stake in
     * @param numberOfTokens Number of LP tokens in the farm
     * @return uint The USD value of the LP tokens
     */
    function _calculateValueOfPair(address farmAddress, uint numberOfTokens) internal view returns (uint) {
        require(numberOfTokens > 0, "StakingFarmRewards: number of LP tokens in pair must be greater than 0");

        address baseUbeswapAdapterAddress = ADDRESS_RESOLVER.getContractAddress("BaseUbeswapAdapter"); 

        address pair = IStakingRewards(farmAddress).stakingToken();
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
     * @notice Stakes the given LP token amount.
     */
    function stake(uint amount, address farmAddress) external override nonReentrant updateReward(msg.sender, farmAddress) {
        require(amount > 0, "StakingFarmRewards: Staked amount must be greater than 0");
        require(farmAddress != address(0), "StakingFarmRewards: invalid farm address");

        uint vestingTimestamp = block.timestamp.add(30 days);
        appendVestingEntry(msg.sender, vestingTimestamp, amount, farmAddress);

        //Transfer LP tokens from user and stake in farm
        address stakingToken = IStakingRewards(farmAddress).stakingToken();
        IERC20(stakingToken).transferFrom(msg.sender, address(this), amount);
        IStakingRewards(stakingToken).stake(amount); //This contract has custody of staked tokens

        emit Staked(msg.sender, amount, vestingTimestamp, farmAddress, block.timestamp);
    }

    /**
     * @notice Allow a user to withdraw any LP token in their schedule that have vested.
     */
    function vest(address farmAddress) external override nonReentrant updateReward(msg.sender, farmAddress) {
        require(farmAddress != address(0), "StakingFarmRewards: invalid farm address");

        uint numEntries = numVestingEntries(msg.sender, farmAddress);
        uint total;

        for (uint i = 0; i < numEntries; i++)
        {
            uint time = getVestingTime(msg.sender, i, farmAddress);
            /* The list is sorted; when we reach the first future time, bail out. */
            if (time > block.timestamp)
            {
                break;
            }

            uint qty = getVestingQuantity(msg.sender, i, farmAddress);

            if (qty > 0)
            {
                vestingSchedules[farmAddress][msg.sender][i] = [0, 0];
                total = total.add(qty);
            }
        }

        if (total != 0)
        {
            //Unstake from farm and claim available UBE rewards; unstakes full position by default
            IStakingRewards(farmAddress).exit();

            //Update state variables and transfer tokens to user
            address stakingToken = IStakingRewards(farmAddress).stakingToken();
            totalVestedBalance[farmAddress] = totalVestedBalance[farmAddress].sub(total);
            totalVestedAccountBalance[farmAddress][msg.sender] = totalVestedAccountBalance[farmAddress][msg.sender].sub(total);
            IERC20(stakingToken).transfer(msg.sender, total);

            //Stake remaining tokens back into farm
            uint remainingTokens = IERC20(stakingToken).balanceOf(address(this));
            IStakingRewards(farmAddress).stake(remainingTokens);

            emit Vested(msg.sender, block.timestamp, total, farmAddress);
        }

        //Claim TGEN rewards
        getReward(farmAddress);
    }

    /**
     * @notice Allow a user to claim any available staking rewards for the given farm.
     */
    function getReward(address farmAddress) public override nonReentrant updateReward(msg.sender, farmAddress) {
        require(farmAddress != address(0), "StakingFarmRewards: invalid farm address");

        address baseTradegenAddress = ADDRESS_RESOLVER.getContractAddress("TradegenERC20");
        uint reward = rewards[farmAddress][msg.sender];

        if (reward > 0)
        {
            rewards[farmAddress][msg.sender] = 0;
            IERC20(baseTradegenAddress).transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward, farmAddress, block.timestamp);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @notice Initialize the lastUpdateTime of each Ubeswap farm; meant to be called once
     */
    function initializeFarms() external onlyOwner {
        require(!initialized, "Already initialized farms");
        //Initialize lastUpdateTime of each available Ubeswap farm
        address baseUbeswapAdapterAddress = ADDRESS_RESOLVER.getContractAddress("BaseUbeswapAdapter");
        address[] memory farms = IBaseUbeswapAdapter(baseUbeswapAdapterAddress).getAvailableUbeswapFarms();
        for (uint i = 0; i < farms.length; i++)
        {
            lastUpdateTime[farms[i]] = block.timestamp;
        }

        initialized = true;
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account, address farmAddress) {
        require(farmAddress != address(0), "StakingFarmRewards: invalid farm address");

        rewardPerTokenStored[farmAddress] = rewardPerToken(farmAddress);
        lastUpdateTime[farmAddress] = block.timestamp;
        if (account != address(0)) {
            rewards[farmAddress][account] = earned(account, farmAddress);
            userRewardPerTokenPaid[farmAddress][account] = rewardPerTokenStored[farmAddress];
        }
        _;
    }

    /* ========== EVENTS ========== */

    event Vested(address indexed beneficiary, uint time, uint value, address farmAddress);
    event Staked(address indexed beneficiary, uint total, uint vestingTimestamp, address farmAddress, uint timestamp);
    event RewardPaid(address indexed user, uint amount, address farmAddress, uint timestamp);
}