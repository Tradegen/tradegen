// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
pragma experimental ABIEncoderV2;

//Adapters
import './interfaces/IBaseUbeswapAdapter.sol';

//Interfaces
import './interfaces/IPool.sol';
import './interfaces/ISettings.sol';
import './interfaces/IAddressResolver.sol';
import './interfaces/IAssetHandler.sol';
import './interfaces/IAssetVerifier.sol';
import './interfaces/IVerifier.sol';
import './interfaces/Ubeswap/IStakingRewards.sol';

//Libraries
import "./openzeppelin-solidity/SafeMath.sol";
import "./openzeppelin-solidity/SafeERC20.sol";

contract Pool is IPool {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IAddressResolver public ADDRESS_RESOLVER;
   
    string public _name;
    uint public _totalSupply;
    address public _manager;
    uint public _performanceFee; //expressed as %
    uint256 public _tokenPriceAtLastFeeMint;

    mapping (address => uint) public _balanceOf;

    //Asset positions
    mapping (uint => address) public _positionKeys;
    uint public numberOfPositions;
    mapping (address => uint) public positionToIndex; //maps to (index + 1), with index 0 representing position not found

    constructor(string memory poolName, uint performanceFee, address manager, IAddressResolver addressResolver) {
        _name = poolName;
        _manager = manager;
        _performanceFee = performanceFee;
        ADDRESS_RESOLVER = addressResolver;

        _tokenPriceAtLastFeeMint = 10**18;
    }

    /* ========== VIEWS ========== */

    /**
    * @dev Returns the name of the pool
    * @return string The name of the pool
    */
    function name() external view override returns (string memory) {
        return _name;
    }

    /**
    * @dev Return the pool manager's address
    * @return address Address of the pool's manager
    */
    function getManagerAddress() external view override returns (address) {
        return _manager;
    }

    /**
    * @dev Returns the USD value of the asset
    * @param asset Address of the asset
    * @param assetHandlerAddress Address of AssetHandler contract
    */
    function getAssetValue(address asset, address assetHandlerAddress) public view override returns (uint) {
        require(asset != address(0), "Pool: invalid asset address");
        require(assetHandlerAddress != address(0), "Pool: invalid asset handler address");

        uint USDperToken = IAssetHandler(assetHandlerAddress).getUSDPrice(asset);
        uint numberOfDecimals = IAssetHandler(assetHandlerAddress).getDecimals(asset);
        uint balance = IAssetHandler(assetHandlerAddress).getBalance(address(this), asset);

        return balance.mul(USDperToken).div(10 ** numberOfDecimals);
    }

    /**
    * @dev Returns the currency address and balance of each position the pool has, as well as the cumulative value
    * @return (address[], uint[], uint) Currency address and balance of each position the pool has, and the cumulative value of positions
    */
    function getPositionsAndTotal() public view override returns (address[] memory, uint[] memory, uint) {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address[] memory addresses = new address[](numberOfPositions);
        uint[] memory balances = new uint[](numberOfPositions);
        uint sum;

        //Calculate USD value of each asset
        for (uint i = 0; i < numberOfPositions; i++)
        {
            balances[i] = IAssetHandler(assetHandlerAddress).getBalance(address(this), _positionKeys[i.add(1)]);
            addresses[i] = _positionKeys[i.add(1)];

            uint numberOfDecimals = IAssetHandler(assetHandlerAddress).getDecimals(_positionKeys[i.add(1)]);
            uint USDperToken = IAssetHandler(assetHandlerAddress).getUSDPrice(_positionKeys[i.add(1)]);
            uint positionBalanceInUSD = balances[i].mul(USDperToken).div(10 ** numberOfDecimals);
            sum = sum.add(positionBalanceInUSD);
        }

        return (addresses, balances, sum);
    }

    /**
    * @dev Returns the amount of cUSD the pool has to invest
    * @return uint Amount of cUSD the pool has available
    */
    function getAvailableFunds() public view override returns (uint) {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address stableCoinAddress = IAssetHandler(assetHandlerAddress).getStableCoinAddress();

        return IERC20(stableCoinAddress).balanceOf(address(this));
    }

    /**
    * @dev Returns the value of the pool in USD
    * @return uint Value of the pool in USD
    */
    function getPoolValue() public view override returns (uint) {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        uint sum = 0;

        //Get USD value of each asset
        for (uint i = 1; i <= numberOfPositions; i++)
        {
            sum = sum.add(getAssetValue(_positionKeys[i], assetHandlerAddress));
        }
        
        return sum;
    }

    /**
    * @dev Returns the balance of the user in USD
    * @return uint Balance of the user in USD
    */
    function getUSDBalance(address user) public view override returns (uint) {
        require(user != address(0), "Invalid address");

        uint poolValue = getPoolValue();

        return poolValue.mul(_balanceOf[user]).div(_totalSupply);
    }

    /**
    * @dev Returns the number of pool tokens the user has
    * @param user Address of the user
    * @return uint Number of pool tokens the user has
    */
    function balanceOf(address user) public view override returns (uint) {
        require(user != address(0), "Invalid user address");

        return _balanceOf[user];
    }

    /**
    * @dev Returns the total supply of LP tokens in the pool
    * @return uint Total supply of LP tokens
    */
    function totalSupply() public view override returns (uint) {
        return _totalSupply;
    }

    /**
    * @dev Returns the pool's performance fee
    * @return uint The pool's performance fee
    */
    function getPerformanceFee() public view override returns (uint) {
        return _performanceFee;
    }

    /**
    * @dev Returns the price of the pool's token
    * @return USD price of the pool's token
    */
    function tokenPrice() public view override returns (uint) {
        uint poolValue = getPoolValue();

        return _tokenPrice(poolValue);
    }

    /**
    * @dev Returns the pool manager's available fees
    * @return Pool manager's available fees
    */
    function availableManagerFee() public view override returns (uint) {
        uint poolValue = getPoolValue();

        if (_totalSupply == 0 || poolValue == 0)
        {
            return 0;
        }

        uint currentTokenPrice = _tokenPrice(poolValue);

        if (currentTokenPrice <= _tokenPriceAtLastFeeMint)
        {
            return 0;
        }

        return (currentTokenPrice.sub(_tokenPriceAtLastFeeMint)).mul(_totalSupply).mul(_performanceFee).div(10000).div(currentTokenPrice);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
    * @dev Mints the pool manager's fee
    */
    function mintManagerFee() external onlyPoolManager {
        _mintManagerFee();
    }

    /**
    * @dev Deposits the given USD amount into the pool
    * @notice Call cUSD.approve() before calling this function
    * @param amount Amount of USD to deposit into the pool
    */
    function deposit(uint amount) external override {
        require(amount > 0, "Pool: Deposit must be greater than 0");

        uint poolBalance = getPoolValue();
        uint numberOfLPTokens = (_totalSupply > 0) ? _totalSupply.mul(amount).div(poolBalance) : amount;

        _balanceOf[msg.sender] = _balanceOf[msg.sender].add(numberOfLPTokens);
        _totalSupply = _totalSupply.add(numberOfLPTokens);

        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address stableCoinAddress = IAssetHandler(assetHandlerAddress).getStableCoinAddress();

        IERC20(stableCoinAddress).safeTransferFrom(msg.sender, address(this), amount);

        _addPositionKey(stableCoinAddress);

        emit Deposit(address(this), msg.sender, amount, block.timestamp);
    }

    /**
    * @dev Withdraws the given number of pool tokens from the user
    * @param numberOfPoolTokens Number of pool tokens to withdraw
    */
    function withdraw(uint numberOfPoolTokens) public override {
        require(numberOfPoolTokens > 0, "Pool: number of pool tokens must be greater than 0");
        require(_balanceOf[msg.sender] >= numberOfPoolTokens, "Pool: Not enough pool tokens to withdraw");

        //Mint manager fee
        uint poolValue = _mintManagerFee();
        uint portion = numberOfPoolTokens.mul(10**18).div(_totalSupply);

        //Burn user's pool tokens
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(numberOfPoolTokens);
        _totalSupply = _totalSupply.sub(numberOfPoolTokens);

        uint[] memory amountsWithdrawn = new uint[](numberOfPositions);
        address[] memory assetsWithdrawn = new address[](numberOfPositions);

        uint assetCount = numberOfPositions;
        //Withdraw user's portion of pool's assets
        for (uint i = assetCount; i > 0; i--)
        {
            uint portionOfAssetBalance = _withdrawProcessing(_positionKeys[i], portion);

            if (portionOfAssetBalance > 0)
            {
                IERC20(_positionKeys[i]).safeTransfer(msg.sender, portionOfAssetBalance);

                amountsWithdrawn[i.sub(1)] = portionOfAssetBalance;
                assetsWithdrawn[i.sub(1)] = _positionKeys[i];
            }

            //Remove position keys if pool is liquidated
            if (_totalSupply == 0)
            {
                _removePositionKey(_positionKeys[i]);
            }
        }

        //Set numberOfPositions to 0 if pool is liquidated
        if (_totalSupply == 0)
        {
            numberOfPositions = 0;
        }

        uint valueWithdrawn = poolValue.mul(portion).div(10**18);

        emit Withdraw(address(this), msg.sender, numberOfPoolTokens, valueWithdrawn, assetsWithdrawn, amountsWithdrawn, block.timestamp);
    }

    /**
    * @dev Withdraws the user's full investment
    */
    function exit() external override {
        withdraw(balanceOf(msg.sender));
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
    * @dev Executes a transaction on behalf of the pool; lets pool talk to other protocols
    * @param to Address of external contract
    * @param data Bytes data for the transaction
    */
    function executeTransaction(address to, bytes memory data) external onlyPoolManager {
        require(to != address(0), "Pool: invalid 'to' address");

        //First try to get contract verifier
        address verifier = ADDRESS_RESOLVER.contractVerifiers(to);
        //Try to get asset verifier if no contract verifier found
        if (verifier == address(0))
        {
            address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
            verifier = IAssetHandler(assetHandlerAddress).getVerifier(to);

            //'to' address is an asset; need to check if asset is valid
            if (verifier != address(0))
            {
                require(IAssetHandler(assetHandlerAddress).isValidAsset(to), "Pool: invalid asset");

                _addPositionKey(to);
            }
        }
        
        require(verifier != address(0), "Pool: invalid verifier");
        
        (bool valid, address receivedAsset) = IVerifier(verifier).verify(address(ADDRESS_RESOLVER), address(this), to, data);
        require(valid, "Pool: invalid transaction");
        
        (bool success, ) = to.call(data);
        require(success, "Pool: transaction failed to execute");

        _addPositionKey(receivedAsset);

        emit ExecutedTransaction(address(this), _manager, to, success, block.timestamp);
    }

    /**
    * @dev Removes the pool's empty positions from position keys
    */
    function removeEmptyPositions() external onlyPoolManager {
        uint assetCount = numberOfPositions;

        for (uint i = assetCount; i > 0; i--)
        {
            _removePositionKey(_positionKeys[i]);
        }

        emit RemovedEmptyPositions(address(this), _manager, block.timestamp);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
    * @dev Adds the given currency to position keys
    * @param currency Address of token to add
    */
    function _addPositionKey(address currency) internal {
        //Add token to positionKeys if not currently in positionKeys
        if (currency != address(0) && positionToIndex[currency] == 0)
        {
            numberOfPositions = numberOfPositions.add(1);
            _positionKeys[numberOfPositions] = currency;
            positionToIndex[currency] = numberOfPositions;
        }
    }

    /**
    * @dev Removes the given currency to position keys
    * @param currency Address of token to remove
    */
    function _removePositionKey(address currency) internal {
        require(currency != address(0), "Pool: invalid asset address");

        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");

        //Remove currency from positionKeys if no balance left; account for dust
        if (IAssetHandler(assetHandlerAddress).getBalance(address(this), currency) < 1000)
        {
            if (_positionKeys[positionToIndex[currency]] != _positionKeys[numberOfPositions])
            {
                _positionKeys[positionToIndex[currency]] = _positionKeys[numberOfPositions];
                positionToIndex[_positionKeys[numberOfPositions]] = positionToIndex[currency];
            }
            delete _positionKeys[numberOfPositions];
            delete positionToIndex[currency];
            numberOfPositions = numberOfPositions.sub(1);
        }
    }

    /**
    * @dev Calculates the price of a pool token
    * @param _poolValue Value of the pool in USD
    * @return Price of a pool token
    */
    function _tokenPrice(uint _poolValue) internal view returns (uint) {
        if (_poolValue == 0)
        {
            return 0;
        }

        if (_totalSupply == 0)
        {
            return 10**18;
        }

        return _poolValue.mul(10**18).div(_totalSupply);
    }

    /**
    * @dev Mints the pool manager's available fees
    * @return Pool's USD value
    */
    function _mintManagerFee() internal returns(uint) {
        uint poolValue = getPoolValue();

        uint availableFee = availableManagerFee();

        // Ignore dust when minting performance fees
        if (availableFee < 10000)
        {
            return 0;
        }

        _balanceOf[_manager] = _balanceOf[_manager].add(availableFee);
        _totalSupply = _totalSupply.add(availableFee);

        _tokenPriceAtLastFeeMint = _tokenPrice(poolValue);

        emit MintedManagerFee(address(this), _manager, availableFee, block.timestamp);

        return poolValue;
    }

    /**
    * @dev Performs additional processing when withdrawing an asset (such as checking for staked tokens)
    * @param asset Address of asset to withdraw
    * @param portion User's portion of pool's asset balance
    * @return Amount of tokens to withdraw
    */
    function _withdrawProcessing(address asset, uint portion) internal returns (uint) {
        address assetHandlerAddress = ADDRESS_RESOLVER.getContractAddress("AssetHandler");
        address verifier = IAssetHandler(assetHandlerAddress).getVerifier(asset);

        (address withdrawAsset, uint withdrawBalance, IAssetVerifier.MultiTransaction[] memory transactions) = IAssetVerifier(verifier).prepareWithdrawal(address(this), asset, portion);

        if (transactions.length > 0)
        {
            uint initialAssetBalance;
            if (withdrawAsset != address(0))
            {
                initialAssetBalance = IERC20(withdrawAsset).balanceOf(address(this));
            }

            //Execute each transaction
            for (uint i = 0; i < transactions.length; i++)
            {
                (bool success,) = (transactions[i].to).call(transactions[i].txData);
                require(success, "Pool: failed to withdraw tokens");
            }

            //Account for additional tokens added (withdrawing staked LP tokens)
            if (withdrawAsset != address(0))
            {
                withdrawBalance = withdrawBalance.add(IERC20(withdrawAsset).balanceOf(address(this))).sub(initialAssetBalance);
            }
        }

        return withdrawBalance;
    }

    /* ========== MODIFIERS ========== */

    modifier onlyPoolManager() {
        require(msg.sender == _manager, "Pool: Only pool's manager can call this function");
        _;
    }

    /* ========== EVENTS ========== */

    event Deposit(address indexed poolAddress, address indexed userAddress, uint amount, uint timestamp);
    event Withdraw(address indexed poolAddress, address indexed userAddress, uint numberOfPoolTokens, uint valueWithdrawn, address[] assets, uint[] amountsWithdrawn, uint timestamp);
    event MintedManagerFee(address indexed poolAddress, address indexed manager, uint amount, uint timestamp);
    event ExecutedTransaction(address indexed poolAddress, address indexed manager, address to, bool success, uint timestamp);
    event RemovedEmptyPositions(address indexed poolAddress, address indexed manager, uint timestamp);
}