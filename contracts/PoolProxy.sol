pragma solidity >=0.5.0;

//Interfaces
import './interfaces/IPool.sol';
import './interfaces/ISettings.sol';
import './interfaces/IAddressResolver.sol';

import './PoolManager.sol';
import './Ownable.sol';

contract PoolProxy is PoolManager {
    using SafeMath for uint;

    address private immutable _owner;

    constructor(IAddressResolver addressResolver) PoolManager(addressResolver) public {
        _owner = msg.sender;
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Returns the address of each pool the user manages
    * @param user Address of the user
    * @return address[] The address of each pool the user manages
    */
    function getUserManagedPools(address user) public view returns(address[] memory) {
        return _getUserManagedPools(user);
    }

    /**
    * @dev Returns the address of each pool the user is invested in
    * @param user Address of the user
    * @return address[] The address of each pool the user is invested in
    */
    function getUserInvestedPools(address user) public view returns(address[] memory) {
        return _getUserInvestedPools(user);
    }

    /**
    * @dev Returns the address of each pool the user is staked in
    * @param user Address of the user
    * @return address[] The address of each pool the user is staked in
    * @return uint Number of pools the user is staked in
    */
    function getUserStakedPools(address user) public view returns(address[] memory, uint) {
        return _getUserStakedPools(user);
    }

    /**
    * @dev Returns the address of each available pool
    * @return address[] The address of each available pool
    */
    function getAvailablePools() public view returns(address[] memory) {
        return _getAvailablePools();
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @dev Creates a new pool
    * @param poolName Name of the pool
    * @param performanceFee Performance fee for the pool
    */
    function createPool(string memory poolName, uint performanceFee) external {
        address settingsAddress = ADDRESS_RESOLVER.getContractAddress("Settings");
        uint maximumPerformanceFee = ISettings(settingsAddress).getParameterValue("MaximumPerformanceFee");
        uint maximumNumberOfPoolsPerUser = ISettings(settingsAddress).getParameterValue("MaximumNumberOfPoolsPerUser");

        require(bytes(poolName).length < 30, "Pool name must have less than 30 characters");
        require(performanceFee <= maximumPerformanceFee, "Cannot exceed maximum performance fee");
        require(_getUserManagedPools(msg.sender).length < maximumNumberOfPoolsPerUser, "Cannot exceed maximum number of pools per user");

        address poolAddress = _createPool(poolName, performanceFee, msg.sender);

        ADDRESS_RESOLVER.addPoolAddress(poolAddress);
    }

    /**
    * @dev Withdraw cUSD from the given pool
    * @param poolAddress Address of the pool
    * @param amount Amount of cUSD to withdraw from the pool
    */
    function withdraw(address poolAddress, uint amount) external isValidPoolAddress(poolAddress) {
        require(amount > 0, "Withdrawal amount must be greater than 0");

        IPool(poolAddress).withdraw(msg.sender, amount);

        _withdraw(msg.sender, poolAddress);

        emit WithdrewFundsFromPool(msg.sender, poolAddress, amount, block.timestamp);
    }

    /**
    * @dev Deposit cUSD into the given pool
    * @notice Call StableToken.approve() before calling this function
    * @param poolAddress Address of the pool
    * @param amount Amount of cUSD to deposit into the pool
    */
    function deposit(address poolAddress, uint amount) external isValidPoolAddress(poolAddress) {
        require(amount > 0, "Deposit amount must be greater than 0");

        _deposit(msg.sender, poolAddress);

        address settingsAddress = ADDRESS_RESOLVER.getContractAddress("Settings");
        address stableCoinAddress = ISettings(settingsAddress).getStableCoinAddress();

        IERC20(stableCoinAddress).transferFrom(msg.sender, address(this), amount);
        IERC20(stableCoinAddress).approve(poolAddress, amount);
        IPool(poolAddress).deposit(msg.sender, amount);

        emit DepositedFundsIntoPool(msg.sender, poolAddress, amount, block.timestamp);
    }

    /**
    * @dev Places an order to buy/sell the given currency on behalf of the pool
    * @param poolAddress Address of the pool
    * @param currencyKey Address of currency to trade
    * @param buyOrSell Whether the user is buying or selling
    * @param numberOfTokens Number of tokens of the given currency
    */
    function placeOrder(address poolAddress, address currencyKey, bool buyOrSell, uint numberOfTokens) external isValidPoolAddress(poolAddress) onlyManager(poolAddress) {
        require(poolAddress != address(0), "Invalid pool address");
        require(currencyKey != address(0), "Invalid currency key");
        require(numberOfTokens > 0, "PoolProxy: Number of tokens must be greater than 0");

        IPool(poolAddress).placeOrder(currencyKey, buyOrSell, numberOfTokens);

        emit PlacedOrder(poolAddress, currencyKey, buyOrSell, numberOfTokens, block.timestamp);
    }

    /**
    * @dev Sets the pool's farm address to the specified address
    * @notice Only the PoolProxy contract owner can call this function
    * @param poolAddress Address of the pool
    * @param farmAddress Address of the farm
    */
    function setFarmAddress(address poolAddress, address farmAddress) external isValidPoolAddress(poolAddress) {
        require(msg.sender == _owner, "Only the contract owner can call this function");
        require(farmAddress != address(0), "Invalid farm address");

        IPool(poolAddress).setFarmAddress(farmAddress);

        emit UpdatedFarmAddress(poolAddress, farmAddress, block.timestamp);
    }

    /* ========== EVENTS ========== */

    event DepositedFundsIntoPool(address indexed user, address indexed poolAddress, uint amount, uint timestamp);
    event WithdrewFundsFromPool(address indexed user, address indexed poolAddress, uint amount, uint timestamp);
    event PlacedOrder(address indexed poolAddress, address indexed currencyKey, bool buyOrSell, uint numberOfTokens, uint timestamp);
    event UpdatedFarmAddress(address indexed poolAddress, address farmAddress, uint timestamp);
}