pragma solidity >=0.5.0;

import './interfaces/IERC20.sol';
import './interfaces/IPool.sol';

import './libraries/SafeMath.sol';

import './AddressResolver.sol';
import './Settings.sol';
import './TradegenERC20.sol';

contract Pool is IPool, AddressResolver {
    using SafeMath for uint;

    string public _name;
    uint public _supply;
    address public _manager;
    uint public _performanceFee; //expressed as %

    address[] public _positionKeys;
    uint public cUSDdebt;
    uint public TGENdebt;

    mapping (address => uint) public balanceOf;
    mapping (address => uint) public investorToIndex; //maps to (index + 1) in investors array; index 0 represents investor not found
    address[] public investors;

    constructor(string memory name, uint performanceFee, address manager) public onlyPoolManager(msg.sender) {
        _name = name;
        _manager = manager;
        _performanceFee = performanceFee;
    }

    /* ========== VIEWS ========== */

    function getPoolName() public view override returns (string memory) {
        return _name;
    }

    function getManagerAddress() public view override returns (address) {
        return _manager;
    }

    function getInvestors() public view override returns (InvestorAndBalance[] memory) {
        InvestorAndBalance[] memory temp = new InvestorAndBalance[](investors.length);

        for (uint i = 0; i < investors.length; i++)
        {
            temp[i] = InvestorAndBalance(investors[i], balanceOf[investors[i]]);
        }

        return temp;
    }

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

    function getAvailableFunds() public view override returns (uint) {
        return IERC20(Settings(getSettingsAddress()).getStableCurrencyAddress()).balanceOf(address(this));
    }

    function getPoolBalance() public view override returns (uint) {
        (, uint positionBalance) = getPositionsAndTotal();
        uint availableFunds = getAvailableFunds();
        
        return availableFunds.add(positionBalance);
    }

    function getUserBalance(address user) public view override returns (uint) {
        require(user != address(0), "Invalid address");

        uint poolBalance = getPoolBalance();

        return poolBalance.mul(balanceOf[user]).div(_supply);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(uint amount) external override {
        require(amount > 0, "Deposit must be greater than 0");

        //add user to pool's investors
        if (balanceOf[msg.sender] == 0)
        {
            investors.push(msg.sender);
            investorToIndex[msg.sender] = investors.length;
        }

        IERC20(Settings(getSettingsAddress()).getStableCurrencyAddress()).transferFrom(msg.sender, address(this), amount);
        balanceOf[msg.sender].add(amount); //add 1 LP token per cUSD
        _supply.add(amount);

        //settle debt
        _settleDebt(amount);

        emit DepositedFundsIntoPool(msg.sender, address(this), amount, block.timestamp);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function withdraw(address user, uint amount) public override onlyPoolProxy(msg.sender) {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Withdrawal must be greater than 0");

        uint poolBalance = getPoolBalance();
        uint userBalance = getUserBalance(user);
        uint numberOfLPTokens = amount.mul(poolBalance).div(_supply);
        uint cUSDtoTGEN = 1; //TODO: get exchange rate from Ubeswap
        uint TGENequivalent = amount.mul(cUSDtoTGEN);
        uint fee = (userBalance > balanceOf[user]) ? _payPerformanceFee(user, userBalance, amount, cUSDtoTGEN) : 0;

        require(userBalance >= amount, "Not enough funds");

        cUSDdebt.add(amount);
        TGENdebt.add(TGENequivalent);
        balanceOf[user].sub(numberOfLPTokens);
        _supply.sub(numberOfLPTokens);

        //remove user from pool's investors user has no funds left in pool
        if (balanceOf[user] == 0)
        {
            uint index = investorToIndex[user];
            address lastInvestor = investors[investors.length - 1];
            investorToIndex[lastInvestor] = index;
            investors[index - 1] = lastInvestor;
            investors.pop();
            delete investorToIndex[user];
        }

        TradegenERC20(getBaseTradegenAddress()).sendRewards(user, TGENequivalent.sub(fee));

        emit WithdrewFundsFromPool(msg.sender, address(this), amount, block.timestamp);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _settleDebt(uint amount) internal {
        require(amount > 0, "Amount must be greater than 0");

        if (cUSDdebt > 0)
        {
            if (amount >= cUSDdebt)
            {
                cUSDdebt = 0;
                TGENdebt = 0;
            }
            else
            {
                uint TGENdebtReduction = amount.mul(TGENdebt).div(cUSDdebt);
                cUSDdebt.sub(amount);
                TGENdebt.sub(TGENdebtReduction);
            }
        }
    }

    function _payPerformanceFee(address user, uint userBalance, uint amount, uint exchangeRate) internal returns (uint) {
        uint profit = userBalance.sub(balanceOf[user]);
        uint ratio = amount.mul(profit).div(userBalance);
        uint fee = ratio.mul(exchangeRate).mul(_performanceFee).div(100);

        TradegenERC20(getBaseTradegenAddress()).sendRewards(_manager, fee);

        emit PaidPerformanceFee(user, address(this), fee, block.timestamp);

        return fee;
    }

    /* ========== EVENTS ========== */

    event DepositedFundsIntoPool(address indexed user, address indexed poolAddress, uint amount, uint timestamp);
    event WithdrewFundsFromPool(address indexed user, address indexed poolAddress, uint amount, uint timestamp);
    event PaidPerformanceFee(address indexed user, address indexed poolAddress, uint amount, uint timestamp);
}