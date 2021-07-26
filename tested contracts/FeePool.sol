pragma solidity >=0.5.0;

//Libraries
import './libraries/SafeMath.sol';

// Inheritance
import "./Ownable.sol";
import './interfaces/IFeePool.sol';

// Internal references
import "./interfaces/IERC20.sol";
import "./interfaces/IAddressResolver.sol";
import "./adapters/interfaces/IBaseUbeswapAdapter.sol";

contract FeePool is Ownable, IFeePool {
    using SafeMath for uint;

    IAddressResolver public immutable ADDRESS_RESOLVER;

    mapping (address => uint) public balances;
    address[] public positionKeys;
    uint public totalSupply;

    constructor(IAddressResolver _addressResolver) public Ownable() {
        ADDRESS_RESOLVER = _addressResolver;
    }

    /* ========== VIEWS ========== */

    /**
    * @notice Returns the number of fee tokens the user has
    * @param account Address of the user
    * @return uint Number of fee tokens
    */
    function getTokenBalance(address account) external view override returns (uint) {
        require(account != address(0), "Invalid address");

        return balances[account];
    }

    /**
    * @dev Returns the currency address and balance of each position the pool has, as well as the cumulative value
    * @return (address[], uint[], uint) Currency address and balance of each position the pool has, and the cumulative value of positions
    */
    function getPositionsAndTotal() public view override returns (address[] memory, uint[] memory, uint) {
        address baseUbeswapAdapterAddress = ADDRESS_RESOLVER.getContractAddress("BaseUbeswapAdapter");
        address[] memory addresses = new address[](positionKeys.length);
        uint[] memory positionBalances = new uint[](positionKeys.length);
        uint sum = 0;

        for (uint i = 0; i < positionKeys.length; i++)
        {
            positionBalances[i] = IERC20(positionKeys[i]).balanceOf(address(this));
            addresses[i] = positionKeys[i];

            uint numberOfDecimals = IERC20(positionKeys[i]).decimals();
            uint USDperToken = IBaseUbeswapAdapter(baseUbeswapAdapterAddress).getPrice(positionKeys[i]);
            uint positionBalanceInUSD = positionBalances[i].mul(USDperToken).div(10 ** numberOfDecimals);
            sum = sum.add(positionBalanceInUSD);
        }

        return (addresses, positionBalances, sum);
    }

    /**
    * @dev Returns the value of the pool in USD
    * @return uint Value of the pool in USD
    */
    function getPoolBalance() public view override returns (uint) {
        (,, uint positionBalance) = getPositionsAndTotal();
        
        return positionBalance;
    }

    /**
    * @dev Returns the balance of the user in USD
    * @return uint Balance of the user in USD
    */
    function getUSDBalance(address user) public view override returns (uint) {
        require(user != address(0), "Invalid address");

        uint poolBalance = getPoolBalance();

        return poolBalance.mul(balances[user]).div(totalSupply);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @notice Allow a user to claim available fees in the specified currency
    * @param currencyKey Address of the currency to claim 
    * @param numberOfTokens Number of tokens to claim in the given currency
    */
    function claimAvailableFees(address currencyKey, uint numberOfTokens) external override {
        require(currencyKey != address(0), "FeePool: Invalid currency key");
        require(numberOfTokens > 0, "FeePool: Number of tokens must be greater than 0");

        uint poolAssetBalance = IERC20(currencyKey).balanceOf(address(this));
        uint tokensAvailableToWithdraw = poolAssetBalance.mul(balances[msg.sender]).div(totalSupply);

        require(tokensAvailableToWithdraw >= numberOfTokens, "FeePool: Not enough tokens in given currency");

        //Calculate number of fee tokens
        address baseUbeswapAdapterAddress = ADDRESS_RESOLVER.getContractAddress("BaseUbeswapAdapter");
        uint USDperAssetToken = IBaseUbeswapAdapter(baseUbeswapAdapterAddress).getPrice(currencyKey);
        uint numberOfDecimals = IERC20(currencyKey).decimals();
        uint feeUSDValue = USDperAssetToken.mul(numberOfTokens).div(10 ** numberOfDecimals);
        uint poolUSDBalance = getPoolBalance();
        uint numberOfFeeTokens = totalSupply.mul(feeUSDValue).div(poolUSDBalance);

        //Update state variables
        balances[msg.sender] = balances[msg.sender].sub(numberOfFeeTokens);
        totalSupply = totalSupply.sub(numberOfFeeTokens);

        //Transfer asset to user
        IERC20(currencyKey).transfer(msg.sender, numberOfTokens);

        //Find index of position in positionKeys array
        uint index;
        for (index = 0; index < positionKeys.length; index++)
        {
            if (positionKeys[index] == currencyKey)
            {
                break;
            }
        }

        //Remove position key if no balance left
        if (IERC20(positionKeys[index]).balanceOf(address(this)) == 0)
        {
            positionKeys[index] = positionKeys[positionKeys.length - 1];
            positionKeys.pop();
        }

        emit ClaimedFees(msg.sender, currencyKey, numberOfTokens, block.timestamp);
    }

    /**
    * @notice Adds fees to user
    * @notice Function gets called by Pool whenever users withdraw for a profit
    * @param user Address of the user
    * @param feeAmount USD value of fee
    */
    function addFees(address user, uint feeAmount) public override onlyPoolOrStrategy {
        require(feeAmount > 0, "Amount must be greater than 0");
        require(user != address(0), "Invalid address");

        uint poolBalance = getPoolBalance();
        uint numberOfFeeTokens = (totalSupply > 0) ? totalSupply.mul(feeAmount).div(poolBalance) : feeAmount;
        balances[user] = balances[user].add(numberOfFeeTokens);
        totalSupply = totalSupply.add(numberOfFeeTokens);

        emit AddedFees(user, feeAmount, block.timestamp);
    }

    /**
    * @notice Adds currency key to positionKeys array if no position yet
    * @notice Function gets called by Pool whenever users pay performance fee
    * @param positions Address of each position the pool/bot had when paying fee
    */
    function addPositionKeys(address[] memory positions) public override onlyPoolOrStrategy {
        //Add positions to positionKeys array if no existing position
        for (uint i = 0; i < positions.length; i++)
        {
            if (IERC20(positions[i]).balanceOf(address(this)) == 0)
            {
                positionKeys.push(positions[i]);
            }
        }
    }

    /* ========== MODIFIERS ========== */

    modifier onlyPoolOrStrategy() {
        require(ADDRESS_RESOLVER.checkIfPoolAddressIsValid(msg.sender) || ADDRESS_RESOLVER.checkIfStrategyAddressIsValid(msg.sender), "Only the Pool or Strategy contract can call this function");
        _;
    }

    /* ========== EVENTS ========== */

    event ClaimedFees(address user, address currencyKey, uint numberOfTokens, uint timestamp);
    event AddedFees(address user, uint numberOfFeeTokens, uint timestamp);
}