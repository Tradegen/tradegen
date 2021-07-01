pragma solidity >=0.5.0;

//Adapters
import './adapters/interfaces/IBaseUbeswapAdapter.sol';

//Interfaces
import './interfaces/IERC20.sol';
import './interfaces/IPool.sol';
import './interfaces/IUserPoolFarm.sol';
import './interfaces/ISettings.sol';
import './interfaces/ITradegen.sol';
import './interfaces/IAddressResolver.sol';

//Libraries
import './libraries/SafeMath.sol';

contract Pool is IPool {
    using SafeMath for uint;

    IAddressResolver public ADDRESS_RESOLVER;
    ISettings public SETTINGS;
    IUserPoolFarm public immutable FARM;
    IERC20 public immutable STABLE_COIN;
    ITradegen public immutable TRADEGEN;
    IBaseUbeswapAdapter public immutable UBESWAP_ADAPTER;
   
    string public _name;
    uint public _supply;
    address public _manager;
    uint public _performanceFee; //expressed as %

    address[] public _positionKeys;

    mapping (address => uint) public balanceOf;
    mapping (address => uint) public investorToIndex; //maps to (index + 1) in investors array; index 0 represents investor not found
    address[] public investors;

    constructor(string memory name, uint performanceFee, address manager, IAddressResolver addressResolver) public onlyPoolManager {
        _name = name;
        _manager = manager;
        _performanceFee = performanceFee;
        ADDRESS_RESOLVER = addressResolver;
        FARM = IUserPoolFarm(ADDRESS_RESOLVER.getContractAddress("UserPoolFarm"));
        SETTINGS = ISettings(ADDRESS_RESOLVER.getContractAddress("Settings"));
        STABLE_COIN = IERC20(SETTINGS.getStableCoinAddress());
        TRADEGEN = ITradegen(ADDRESS_RESOLVER.getContractAddress("BaseTradegen"));
        UBESWAP_ADAPTER = IBaseUbeswapAdapter(ADDRESS_RESOLVER.getContractAddress("BaseUbeswapAdapter"));
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Returns the name of the pool
    * @return string The name of the pool
    */
    function getPoolName() public view override returns (string memory) {
        return _name;
    }

    /**
    * @dev Return the pool manager's address
    * @return address Address of the pool's manager
    */
    function getManagerAddress() public view override returns (address) {
        return _manager;
    }

    /**
    * @dev Returns the name and address of each investor in the pool
    * @return InvestorAndBalance[] The address and balance of each investor in the pool
    */
    function getInvestors() public view override returns (InvestorAndBalance[] memory) {
        InvestorAndBalance[] memory temp = new InvestorAndBalance[](investors.length);

        for (uint i = 0; i < investors.length; i++)
        {
            temp[i] = InvestorAndBalance(investors[i], balanceOf[investors[i]]);
        }

        return temp;
    }

    /**
    * @dev Returns the currency address and balance of each position the pool has, as well as the cumulative value
    * @return (PositionKeyAndBalance[], uint) Currency address and balance of each position the pool has, and the cumulative value of positions
    */
    function getPositionsAndTotal() public view override returns (PositionKeyAndBalance[] memory, uint) {
        PositionKeyAndBalance[] memory temp = new PositionKeyAndBalance[](_positionKeys.length);
        uint sum = 0;

        for (uint i = 0; i < _positionKeys.length; i++)
        {
            uint positionBalance = IERC20(_positionKeys[i]).balanceOf(address(this));
            temp[i] = PositionKeyAndBalance(_positionKeys[i], positionBalance);
            sum.add(positionBalance);
        }

        return (temp, sum);
    }

    /**
    * @dev Returns the amount of stable coins the pool has to invest
    * @return uint Amount of stable coin the pool has available
    */
    function getAvailableFunds() public view override returns (uint) {
        return STABLE_COIN.balanceOf(address(this));
    }

    /**
    * @dev Returns the value of the pool in USD
    * @return uint Value of the pool in USD
    */
    function getPoolBalance() public view override returns (uint) {
        (, uint positionBalance) = getPositionsAndTotal();
        uint availableFunds = getAvailableFunds();
        
        return availableFunds.add(positionBalance);
    }

    /**
    * @dev Returns the balance of the user in USD
    * @return uint Balance of the user in USD
    */
    function getUserBalance(address user) public view override returns (uint) {
        require(user != address(0), "Invalid address");

        uint poolBalance = getPoolBalance();

        return poolBalance.mul(balanceOf[user]).div(_supply);
    }

    /**
    * @dev Returns the number of LP tokens the user has
    * @param user Address of the user
    * @return uint Number of LP tokens the user has
    */
    function getUserTokenBalance(address user) public view override returns (uint) {
        require(user != address(0), "Invalid user address");

        return balanceOf[user];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @dev Deposits the given USD amount into the pool
    * @param amount Amount of USD to deposit into the pool
    */
    function deposit(uint amount) external override {
        require(amount > 0, "Deposit must be greater than 0");

        //add user to pool's investors
        if (balanceOf[msg.sender] == 0)
        {
            investors.push(msg.sender);
            investorToIndex[msg.sender] = investors.length;
        }

        STABLE_COIN.transferFrom(msg.sender, address(this), amount);
        balanceOf[msg.sender].add(amount); //add 1 LP token per cUSD
        _supply.add(amount);

        emit DepositedFundsIntoPool(msg.sender, address(this), amount, block.timestamp);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @dev Withdraws the given USD amount on behalf of the user
    * @param user Address of user to withdraw
    * @param amount Amount of USD to withdraw from the pool
    */
    function withdraw(address user, uint amount) public override onlyPoolProxy {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Withdrawal must be greater than 0");

        uint userBalance = getUserBalance(user);
        uint numberOfLPTokensStaked = FARM.balanceOf(user, address(this));
        uint availableTokensToWithdraw = userBalance.sub(numberOfLPTokensStaked);

        require(availableTokensToWithdraw >= amount, "Not enough funds");

        uint poolBalance = getPoolBalance();
        uint numberOfLPTokens = amount.mul(poolBalance).div(_supply);
        uint TGENtoUSD = UBESWAP_ADAPTER.getPrice(address(TRADEGEN));
        uint TGENequivalent = amount.mul(TGENtoUSD);
        uint fee = (userBalance > balanceOf[user]) ? _payPerformanceFee(user, userBalance, amount, TGENtoUSD) : 0;

        balanceOf[user].sub(numberOfLPTokens);
        _supply.sub(numberOfLPTokens);

        //Remove user from pool's investors user has no funds left in pool
        if (balanceOf[user] == 0)
        {
            uint index = investorToIndex[user];
            address lastInvestor = investors[investors.length - 1];
            investorToIndex[lastInvestor] = index;
            investors[index - 1] = lastInvestor;
            investors.pop();
            delete investorToIndex[user];
        }

        //Withdraw user's portion of pool's assets
        for (uint i = 0; i < _positionKeys.length; i++)
        {
            uint positionBalance = IERC20(_positionKeys[i]).balanceOf(address(this));
            uint amountToTransfer = positionBalance.mul(numberOfLPTokens).div(_supply);

            IERC20(_positionKeys[i]).approve(user, amountToTransfer);
            IERC20(_positionKeys[i]).transferFrom(address(this), user, amountToTransfer);
        }

        emit WithdrewFundsFromPool(msg.sender, address(this), amount, block.timestamp);
    }

    /**
    * @dev Places an order to buy/sell the given currency
    * @param currencyKey Address of currency to trade
    * @param buyOrSell Whether the user is buying or selling
    * @param numberOfTokens Number of tokens of the given currency
    */
    function placeOrder(address currencyKey, bool buyOrSell, uint numberOfTokens) external override onlyManager {
        require(numberOfTokens > 0, "Number of tokens must be greater than 0");
        require(currencyKey != address(0), "Invalid currency key");
        require(SETTINGS.checkIfCurrencyIsAvailable(currencyKey), "Currency key is not available");

        uint tokenToUSD = UBESWAP_ADAPTER.getPrice(currencyKey);
        address stableCoinAddress = address(STABLE_COIN);
        uint numberOfTokensReceived;

        //buying
        if (buyOrSell)
        {
            require(cUSDdebt == 0, "Need to settle debt before making an opening trade");
            require(getAvailableFunds() >= numberOfTokens.mul(tokenToUSD), "Not enough funds");

            uint amountInUSD = numberOfTokens.div(tokenToUSD);
            uint minAmountOut = numberOfTokens.mul(98).div(100); //max slippage 2%

            numberOfTokensReceived = UBESWAP_ADAPTER.swapFromPool(stableCoinAddress, currencyKey, amountInUSD, minAmountOut);
        }
        //selling
        else
        {
            uint positionIndex;
            for (positionIndex = 0; positionIndex < _positionKeys.length; positionIndex++)
            {
                if (currencyKey == _positionKeys[positionIndex])
                {
                    break;
                }
            }

            require(positionIndex < _positionKeys.length, "Don't have a position in this currency");
            require(IERC20(currencyKey).balanceOf(msg.sender) >= numberOfTokens, "Not enough tokens in this currency");

            uint amountInUSD = numberOfTokens.mul(tokenToUSD);
            uint minAmountOut = amountInUSD.mul(98).div(100); //max slippage 2%

            numberOfTokensReceived = UBESWAP_ADAPTER.swapFromPool(currencyKey, stableCoinAddress, numberOfTokens, minAmountOut);

            //remove position key if no funds left in currency
            if (IERC20(currencyKey).balanceOf(msg.sender) == 0)
            {
                _positionKeys[positionIndex] = _positionKeys[_positionKeys.length - 1];
                _positionKeys.pop();
            }
        }

        emit PlacedOrder(address(this), currencyKey, buyOrSell, numberOfTokens, numberOfTokensReceived, block.timestamp);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
    * @dev Pay performance fee on the user's profit when the user withdraws from the pool
    * @param user Address of the user
    * @param userBalance Number of LP tokens the user has in the pool
    * @param amount Number of LP tokens the user is withdrawing
    * @param exchangeRate Exchange rate from TGEN to cUSD
    * @return uint The amount of performance fee paid (in cUSD)
    */
    function _payPerformanceFee(address user, uint userBalance, uint amount, uint exchangeRate) internal returns (uint) {
        uint profit = userBalance.sub(balanceOf[user]);
        uint ratio = amount.mul(profit).div(userBalance);
        uint fee = ratio.mul(exchangeRate).mul(_performanceFee).div(100);

        TRADEGEN.sendRewards(_manager, fee);

        emit PaidPerformanceFee(user, address(this), fee, block.timestamp);

        return fee;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyManager() {
        require(msg.sender == _manager, "Only manager can call this function");
        _;
    }

    modifier onlyPoolProxy() {
        require(msg.sender == ADDRESS_RESOLVER.getContractAddress("PoolProxy"), "Only PoolProxy contract can call this function");
        _;
    }

    modifier onlyPoolManager() {
        require(msg.sender == ADDRESS_RESOLVER.getContractAddress("PoolManager"), "Only PoolManager contract can call this function");
        _;
    }

    /* ========== EVENTS ========== */

    event DepositedFundsIntoPool(address indexed user, address indexed poolAddress, uint amount, uint timestamp);
    event WithdrewFundsFromPool(address indexed user, address indexed poolAddress, uint amount, uint timestamp);
    event PaidPerformanceFee(address indexed user, address indexed poolAddress, uint amount, uint timestamp);
    event PlacedOrder(address indexed poolAddress, address indexed currencyKey, bool buyOrSell, uint numberOfTokensSwapped, uint numberOfTokensReceived, uint timestamp);
}